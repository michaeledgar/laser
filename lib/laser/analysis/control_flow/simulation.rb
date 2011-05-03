module Laser
  module SexpAnalysis
    module ControlFlow
      # Simulation of a CFG. Requires values for the formal arguments, if any.
      # Stops as soon as an unpredictable statement is reached.
      module Simulation
        class SimulationError < StandardError; end
        class NonDeterminismHappened < StandardError; end
        class SimulationRaised < StandardError; end
        class SimulationNonterminationError < StandardError; end
        # simulates the CFG, with different possible assumptions about
        # how we should treat the global environment/self object.
        def simulate(formal_vals=[], opts={})
          assign_formals(formal_vals, opts)
          begin
            simulate_block(@enter, opts)
          rescue NonDeterminismHappened => err
            puts "Simulation ended at nondeterminism: #{err.message}"
          rescue SimulationNonterminationError => err
            puts "Simulation failed to terminate: #{err.message}"
          end
        end
        
        def do_jump(from, to, opts)
          from.add_flag(to, ControlFlowGraph::EDGE_EXECUTABLE)
          simulate_block(to, opts)
        end
        
        def simulate_block(block, opts)
          return if block.name == 'Exit'
          puts "Entering block #{block.name}"
          # phi nodes always go first
          block.phi_nodes.each do |node|
            simulate_deterministic_phi_node(node, opts)
          end
          block.natural_instructions[0..-2].each do |insn|
            simulate_instruction(insn, opts)
          end
          if block.instructions.empty?
            do_jump(block, block.real_successors.first, opts)
          else
            simulate_exit_instruction(block.instructions.last, opts)
          end
        end
        
        def simulate_exit_instruction(insn, opts)
          puts "Simulating exit insn: #{insn.inspect}"
          successors = insn.block.real_successors.to_a
          case insn[0]
          when :jump, nil
            do_jump(insn.block, successors.first, opts)
          when :branch
            if successors[0].name == insn[2]
            then true_block, false_block = successors[0..1]
            else false_block, true_block = successors[0..1]
            end

            puts "Branching on: #{insn[1].value.inspect}"
            if insn[1].value
            then do_jump(insn.block, true_block, opts)
            else do_jump(insn.block, false_block, opts)
            end
          when :call
            # TODO(adgar): raise edges
            begin
              simulate_instruction(insn, opts)
              do_jump(insn.block, insn.block.normal_successors.first, opts)
            rescue SimulationRaised => err
              do_jump(insn.block, insn.block.abnormal_successors.first, opts)
            end
          end 
        end
        
        IGNORED = [:branch, :jump, :resume, :return]
        def simulate_instruction(insn, opts)
          puts "Simulating insn: #{insn.inspect}"
          return if IGNORED.include?(insn[0])
          case insn[0]
          when :assign then simulate_assignment(insn[1], insn[2], opts)
          when :call
            # cases: special method we intercept, builtin we direct-send, and cfg we simulate
            receiver = insn[2].value
            klass = LaserObject === receiver ? receiver.klass : ClassRegistry[receiver.class.name]
            method = klass.instance_methods[insn[3].to_s]
            if !method
              raise SimulationRaised.new("Method missing: #{klass.name}##{insn[3]}")
            elsif should_simulate_call(method, opts)
              result = simulate_call(receiver, method, insn[4..-2].map(&:value), insn[-1][:block])
              insn[1].bind! result if insn[1]
            else
              raise NonDeterminismHappened.new("Nondeterministic call: #{method.inspect}")
            end
          when :call_vararg
            raise NotImplementedError.new("call_vararg doesn't work yet")
          when :super
            raise NotImplementedError.new("super doesn't work yet")
          when :super_vararg
            raise NotImplementedError.new("super_vararg doesn't work yet")
          end
        end
        
        def simulate_deterministic_phi_node(node, opts)
          which_set = node.operands.reject { |var| UNDEFINED == var.value }
          unless which_set.one?
            raise SimulationError.new("Found phi node with #{which_set.size} "+
                                      "options during toplevel simulation")
          end
          puts "Simulating #{node.inspect}"
          simulate_assignment(node[1], which_set.first, opts)
        end
        
        def simulate_assignment(lhs, rhs, opts)
          if Bindings::GenericBinding === rhs
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
            when ClassRegistry['Class'].singleton_class.instance_methods['new']
              LaserClass.new(ClassRegistry['Class'], nil) do |klass|
                klass.superclass = args.first
              end
            when ClassRegistry['Module'].singleton_class.instance_methods['new']
              LaserModule.new(ClassRegistry['Module'], nil)
            when ClassRegistry['Module'].instance_methods['===']
              args.first.klass.ancestors.include?(receiver)
            end
          elsif method.builtin
            begin
              receiver.send(method.name, *args)
            rescue Exception => err
              raise SimulationRaised.new(err.inspect)
            end
          else
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
          raise NotImplementedError.new("Formal assignment doesn't work yet") unless formal_vals.empty?
          vertices.each do |block|
            block.successors.each do |succ|
              block.remove_flag(succ, ControlFlowGraph::EDGE_EXECUTABLE)
            end
          end
        end
      end  # Simulation
    end  # ControlFlow
  end  # SexpAnalysis
end  # Laser