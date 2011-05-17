module Laser
  module SexpAnalysis
    module ControlFlow
      # Simulation of a CFG. Requires values for the formal arguments, if any.
      # Stops as soon as an unpredictable statement is reached.
      module Simulation
        class SimulationError < StandardError; end
        class NonDeterminismHappened < StandardError; end
        class SimulationNonterminationError < StandardError; end
        class ExitedAbnormally < StandardError
          def initialize(error)
            @error = error
          end
          def error
            @error
          end
        end
        DEFAULT_SIMULATION_OPTS = {on_raise: :annotate}
        # simulates the CFG, with different possible assumptions about
        # how we should treat the global environment/self object.
        def simulate(formal_vals=[], opts={})
          opts = DEFAULT_SIMULATION_OPTS.merge(opts)
          assign_formals(formal_vals, opts)
          current_block = @enter
          previous_block = nil
          begin
            done = raised = false
            begin
              next_block = simulate_block(current_block, opts.merge(:previous_block => previous_block))
              current_block.add_flag(next_block, ControlFlowGraph::EDGE_EXECUTABLE)
              if next_block.name == 'Exit'
                done = true
                if current_block.has_flag?(next_block, ControlFlowGraph::EDGE_ABNORMAL)
                  raise ExitedAbnormally.new(@final_exception.value)
                end
              end
              current_block, previous_block = next_block, current_block
            end until done
          rescue NonDeterminismHappened => err
            Laser.debug_puts "Simulation ended at nondeterminism: #{err.message}"
            Laser.debug_p err.backtrace
          rescue SimulationNonterminationError => err
            Laser.debug_puts "Simulation failed to terminate: #{err.message}"
            Laser.debug_p err.backtrace
          rescue ExitedAbnormally => err
            if opts[:on_raise] == :annotate
              msg = LaserObject === err.error ? err.error.laser_simulate('message', []) : err.error.message
              Laser.debug_puts "Simulation exited abnormally: #{msg}"
              @root.add_error(TopLevelSimulationRaised.new(msg, @root, err.error))
            elsif opts[:on_raise] = :raise
              raise err
            end
          rescue NotImplementedError => err
            Laser.debug_puts "Simulation attempted: #{err.message}"
            Laser.debug_p err.backtrace
          else
            @final_return.value
          end
        end
        
        def simulate_block(block, opts)
          return if block.name == 'Exit'
          Laser.debug_puts "Entering block #{block.name}"
          # phi nodes always go first
          block.phi_nodes.each do |node|
            simulate_deterministic_phi_node(node, opts)
          end
          block.natural_instructions[0..-2].each do |insn|
            simulate_instruction(insn, opts)
          end
          if block.instructions.empty?
            block.real_successors.first
          else
            simulate_exit_instruction(block.instructions.last, opts)
          end
        end
        
        def simulate_exit_instruction(insn, opts)
          Laser.debug_puts "Simulating exit insn: #{insn.inspect}"
          successors = insn.block.real_successors.to_a
          case insn[0]
          when :jump, nil
            successors.first
          when :branch
            if successors[0].name == insn[2]
            then true_block, false_block = successors[0..1]
            else false_block, true_block = successors[0..1]
            end

            Laser.debug_puts "Branching on: #{insn[1].value.inspect}"
            insn[1].value ? true_block : false_block
          when :call, :call_vararg
            # todo: block edge!
            begin
              simulate_instruction(insn, opts)
              insn.block.normal_successors.first
            rescue ExitedAbnormally => err
              Laser.debug_puts "Exception raised by call, taking abnormal edge. Error: #{err.message}"
              insn.block.abnormal_successors.first
            end
          end 
        end
        
        IGNORED = [:branch, :jump, :resume, :return]
        def simulate_instruction(insn, opts)
          Laser.debug_puts "Simulating insn: #{insn.inspect}"
          return if IGNORED.include?(insn[0])
          case insn[0]
          when :assign then simulate_assignment(insn[1], insn[2], opts)
          when :call, :call_vararg
            args = insn[0] == :call ? insn[4..-2].map(&:value) : insn[4].value
            # cases: special method we intercept, builtin we direct-send, and cfg we simulate
            receiver = insn[2].value
            klass = if Bindings::ConstantBinding === insn[2]
                    then receiver.singleton_class
                    else klass = LaserObject === receiver ? receiver.klass : ClassRegistry[receiver.class.name]
                    end
            method = klass.instance_method(insn[3].to_s)
            if !method
              error_klass = insn.node.type == :zcall ? 'NameError' : 'NoMethodError'
              missing_method_error = ClassRegistry[error_klass].laser_simulate(
                  'new', ["Method missing: #{klass.name}##{insn[3]}", insn[3].to_s])
              Bootstrap::EXCEPTION_STACK.value.push(missing_method_error)
              raise ExitedAbnormally.new(missing_method_error)
            elsif should_simulate_call(method, opts)
              result = simulate_call(receiver, method, args, insn[-1][:block])
              insn[1].bind! result if insn[1]
            else
              raise NonDeterminismHappened.new("Nondeterministic call: #{method.inspect}")
            end
          when :super
            raise NotImplementedError.new("super doesn't work yet")
          when :super_vararg
            raise NotImplementedError.new("super_vararg doesn't work yet")
          end
        end
        
        def simulate_deterministic_phi_node(node, opts)
          Laser.debug_puts "Simulating #{node.inspect} from #{opts[:previous_block].name}"
          index_of_predecessor = node.block.predecessors.to_a.index(opts[:previous_block])
          simulate_assignment(node[1], node[2 + index_of_predecessor], opts)
        end
        
        def simulate_assignment(lhs, rhs, opts)
          if Bindings::Base === rhs
            lhs.bind! rhs.value
          else
            lhs.bind! rhs
          end
        end
        
        def should_simulate_call(method, opts)
          method.predictable && (opts[:mutation] || !method.mutation)
        end
        
        def simulate_call(receiver, method, args, block)
          if method.special
            case method
            when ClassRegistry['Class'].singleton_class.instance_method('allocate')
              LaserObject.new(receiver, nil)
            when ClassRegistry['Class'].singleton_class.instance_method('new')
              LaserClass.new(ClassRegistry['Class'], nil) do |klass|
                klass.superclass = args.first
              end
            when ClassRegistry['Module'].singleton_class.instance_method('new')
              LaserModule.new
            when ClassRegistry['Kernel'].instance_method('require')
              simulate_require(args)
            when ClassRegistry['Module'].instance_method('module_eval')
              simulate_module_eval(args)
            when ClassRegistry['Laser#Magic'].singleton_class.instance_method('get_global')
              Scope::GlobalScope.lookup(args.first).value
            when ClassRegistry['Laser#Magic'].singleton_class.instance_method('set_global')
              Scope::GlobalScope.lookup(args[0]).bind!(args[1])
            when ClassRegistry['Laser#Magic'].singleton_class.instance_method('current_self')
              @simulated_self
            when ClassRegistry['Laser#Magic'].singleton_class.instance_method('current_arity')
              @simulated_args.size
            when ClassRegistry['Laser#Magic'].singleton_class.instance_method('current_argument')
              @simulated_args[args.first]
            when ClassRegistry['Laser#Magic'].singleton_class.instance_method('current_argument_range')
              @simulated_args[args[0], args[1]]
            when ClassRegistry['Laser#Magic'].singleton_class.instance_method('current_exception')
              Bootstrap::EXCEPTION_STACK.value.last
            when ClassRegistry['Laser#Magic'].singleton_class.instance_method('push_exception')
              Bootstrap::EXCEPTION_STACK.value.push args[0]
            when ClassRegistry['Laser#Magic'].singleton_class.instance_method('pop_exception')
              Bootstrap::EXCEPTION_STACK.value.pop
            when Scope::GlobalScope.self_ptr.singleton_class.instance_method('private')
              ClassRegistry['Object'].private(*args)
            when Scope::GlobalScope.self_ptr.singleton_class.instance_method('public')
              ClassRegistry['Object'].public(*args)
            end
          elsif method.builtin
            begin
              receiver.send(method.name, *args)
            rescue Exception => err
              Bootstrap::EXCEPTION_STACK.value.push(err)
              raise ExitedAbnormally.new(err)
            end
          else
            Laser.debug_puts "About to simulate #{method.owner.name}##{method.name}"
            result = method.simulate_with_args(receiver, args, block, mutation: true)
            Laser.debug_puts "Finished simulating #{method.owner.name}##{method.name} => #{result.inspect}"
            result
            # simulate CFG
          end
        end
        
        # Fills in the formal variables with respect to rest args and whatnot.
        # Unused for now because simulation only happens @ top level.
        def assign_formals(formal_vals, opts)
          all_variables.each do |temp|
            temp.bind! UNDEFINED
            temp.inferred_type = nil
          end
          @simulated_block = opts[:block]
          @simulated_self  = opts[:self]
          @simulated_args = formal_vals
          vertices.each do |block|
            block.successors.each do |succ|
              block.remove_flag(succ, ControlFlowGraph::EDGE_EXECUTABLE)
            end
          end
        end
        
        # TODO(adgar): validate arguments
        # TODO(adgar): make errors visible
        def simulate_require(args)
          file = args.first
          load_path = Scope::GlobalScope.lookup('$:').value
          loaded_values = Scope::GlobalScope.lookup('$"').value
          to_load = file + '.rb'
          load_path.each do |path|
            joined = File.join(path, to_load)
            if File.exist?(joined)
              if !loaded_values.include?(joined)
                tree = Annotations.annotate_inputs([[joined, File.read(joined)]], optimize: false)
                #node.errors.concat tree[0][1].all_errors
                return true
              end
              return false
            end
          end
          raise LoadError.new("No such file: #{file}")
        end
        
        def simulate_module_eval(args)
          # essentially: parse, compile with a custom scope + lexical target (cref), simulate.
          if args.size > 0
            text = args[0]
            file = args[1] || "(eval)"
            line = args[2] || 1  # ignored currently
            tree = Sexp.new(RipperPlus.sexp(text), file, text)
            Annotations.ordered_annotations.each do |annotator|
              annotator.annotate_with_text(tree, text)
            end
            custom_scope = ClosedScope.new(Scope::GlobalScope, @simulated_self.binding)
            cfg = GraphBuilder.new(tree, [], custom_scope).build
            cfg.analyze
          end
        end
      end  # Simulation
    end  # ControlFlow
  end  # SexpAnalysis
end  # Laser
