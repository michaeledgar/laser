module Laser
  module Analysis
    module ControlFlow
      INAPPLICABLE = PlaceholderObject.new('INAPPLICABLE')

      # Sparse Conditional Constant Propagation: Wegman and Zadeck
      # Love those IBMers
      # Using Morgan's implementation though.
      module ConstantPropagation
        attr_reader :constants

        # Only public method: mutably turns the CFG into a constant-propagated
        # one. Each binding will have a value assigned to it afterward: either
        # the constant, as a Ruby object (or a proxy to one), UNDEFINED, or VARYING.
        def perform_constant_propagation(opts={})
          opts = {fixed_methods: {}, initial_block: self.enter}.merge(opts)
          
          initialize_constant_propagation(opts)
          visited = Set.new
          worklist = Set.new
          blocklist = Set[opts[:initial_block]]
          while worklist.any? || blocklist.any?
            while worklist.any?
              constant_propagation_for_instruction(
                  worklist.pop, blocklist, worklist, opts)
            end
            while blocklist.any?
              constant_propagation_for_block(
                  blocklist.pop, visited, blocklist, worklist, opts)
            end
          end
          teardown_constant_propagation
          @constants = find_remaining_constants
        end

      private

        def find_remaining_constants
          result = {}
          all_variables.select do |variable|
            variable.value != VARYING && variable.value != UNDEFINED
          end.each do |constant|
            result[constant] = constant.value
          end
          result
        end

        # Initializes the variables, formals, and edges for constant propagation.
        # Morgan, p. 201
        def initialize_constant_propagation(opts)
          @constants.clear
          # value cells for :call nodes that discard their argument.
          @cp_private_cells = Hash.new do |h, k|
            h[k] = Bindings::TemporaryBinding.new(k.hash.to_s, UNDEFINED)
            h[k].inferred_type = nil
            h[k]
          end
          @cp_self_cells = Hash.new do |h, k|
            h[k] = Bindings::TemporaryBinding.new(k.hash.to_s, VARYING)
            h[k].inferred_type = real_self_type
            h[k]
          end
          clear_analyses unless opts[:no_wipe]
          @_cp_fixed_methods = opts[:fixed_methods]
        end

        def teardown_constant_propagation
          @cp_private_cells.clear
          @cp_self_cells.clear
        end

        def cp_cell_for(instruction)
          @cp_private_cells[instruction]
        end
        
        def cp_self_cell(instruction)
          @cp_self_cells[instruction]
        end

        # Simulates a block. As we know, phi nodes execute simultaneously
        # and immediately upon block entry, so first we check phi nodes to
        # see if they form a constant. This happens unconditionally, as
        # phi nodes must be checked repeatedly.
        #
        # Then, if the block hasn't been visited before, simulate the normal
        # instructions, and mark it so it is not visited again.
        #
        # Morgan, p.200
        def constant_propagation_for_block(block, visited, blocklist, worklist, opts)
          block.phi_nodes.each do |phi_node|
            constant_propagation_for_instruction(
                phi_node, blocklist, worklist, opts)
          end
          if visited.add?(block)
            block.natural_instructions.each do |instruction|
              constant_propagation_for_instruction(
                  instruction, blocklist, worklist, opts)
            end
            if block.fall_through_block?
              block.successors.each do |succ|
                constant_propagation_consider_edge block, succ, blocklist
              end
            end
          end
        end
        private :constant_propagation_for_block

        def constant_propagation_for_instruction(instruction, blocklist, worklist, opts)
          return if instruction.type != :phi && instruction.block.executed_predecessors.empty?
          Laser.debug_p(instruction)
          block = instruction.block
          case instruction.type
          when :assign, :phi
            if constant_propagation_evaluate(instruction)
              add_target_uses_to_worklist instruction, worklist
            end
          when :call, :call_vararg, :super, :super_vararg
            changed, raised, raise_changed = constant_propagation_for_call(instruction, opts)
            if changed
              if instruction[1] && instruction[1].value != UNDEFINED
                add_target_uses_to_worklist instruction, worklist
              end
            end
            if raise_changed && instruction == block.instructions.last
              raise_capture_insn = instruction.block.exception_successors.first.instructions.first
              raise_capture_insn[1].bind!(VARYING)
              raise_capture_insn[1].inferred_type = instruction.raise_type
              add_target_uses_to_worklist raise_capture_insn, worklist
            end
            if raised != instruction.raise_frequency && instruction == block.instructions.last
              instruction.raise_frequency = raised
              successors = case raised
                           when :unknown then []
                           when Frequency::MAYBE then block.successors
                           when Frequency::NEVER then block.normal_successors
                           when Frequency::ALWAYS then block.abnormal_successors
                           end
              successors.each do |succ|
                constant_propagation_consider_edge block, succ, blocklist
              end
            end
          when :branch
            constant_propagation_for_branch(instruction, blocklist)
          when :jump, :raise, :return
            succ = block.real_successors.first
            constant_propagation_consider_edge block, succ, blocklist
          when :declare
            case instruction[1]
            when :expect_tuple_size
              # check array/tuple size against expectation - issue warning if fail
              validate_tuple_expectation(instruction)
            end
            # don't do shit
          else
            raise ArgumentError("Unknown instruction evaluation type: #{instruction.type}")
          end
        end

        def add_target_uses_to_worklist(instruction, worklist)
          uses = if instruction[0] == :call && instruction[2] == ClassRegistry['Laser#Magic'].binding &&
                    instruction[3] == :set_global
                   Scope::GlobalScope.lookup(instruction[4].value).uses
                 elsif instruction[0] == :call && instruction[3] == :instance_variable_set &&
                    instruction[4] != UNDEFINED && instruction[4] != VARYING
                   receiver = instruction[2]
                   klass = LaserObject === receiver.value ? receiver.value.normal_class : receiver.expr_type.possible_classes.first
                   klass.instance_variable(instruction[4].value).uses
                 else
                   instruction.explicit_targets.map(&:uses).inject(:|) || []
                 end
          uses.each { |use| worklist.add(use) if use }
        end
        
        # Examines the branch for newly executable edges, and adds them to
        # the blocklist.
        def constant_propagation_for_branch(instruction, blocklist)
          block = instruction.block
          executable_successors = constant_propagation_branch_successors(instruction)
          executable_successors.each do |succ|
            constant_propagation_consider_edge block, succ, blocklist
          end
        end
        
        def constant_propagation_branch_successors(instruction)
          condition = instruction[1]
          case condition.value
          when VARYING
            if Types.overlap?(condition.expr_type, Types::FALSY)
              instruction.block.real_successors
            else
              [instruction.true_successor]
            end
          when UNDEFINED then []
          when nil, false then [instruction.false_successor]
          else [instruction.true_successor]
          end
        end

        def constant_propagation_consider_edge(block, succ, blocklist)
          if !is_executable?(block, succ) && !is_fake?(block, succ)
            add_flag(block, succ, ControlFlowGraph::EDGE_EXECUTABLE)
            blocklist << succ
          end
        end

        def constant_propagation_for_call(instruction, cp_opts)
          target = instruction[1] || cp_cell_for(instruction)
          original = target.value
          old_type = target.inferred_type
          old_raise_type = instruction.raise_type

          if instruction.type == :call
            receiver, method_name, *args, opts = instruction[2..-1]
            components = [receiver, *args]
            fixed_arity = true
          elsif instruction.type == :call_vararg
            receiver, method_name, args, opts = instruction[2..-1]
            components = [receiver, args]
          elsif instruction.type == :super
            *args, opts = instruction[2..-1]
            fixed_arity = issuper = true
            components = args.dup
            receiver = cp_self_cell(instruction)
          elsif instruction.type == :super_vararg
            args, opts = instruction[2..3]
            issuper = true
            components = [args]
            receiver = cp_self_cell(instruction)
          end
          components << opts[:block] if opts[:block]

          if components.any? { |arg| arg.value == UNDEFINED }
            # cannot evaluate unless all args and receiver are defined
            return [false, :unknown]
          end
          # check purity
          methods = instruction.possible_methods(cp_opts)
          # Require precise resolution
          method = methods.size == 1 ? methods.first : nil
          if methods.empty?
            new_value = UNDEFINED
            new_type = Types::TOP
            raised = Frequency::ALWAYS  # NoMethodError
            raise_type = Types::UnionType.new([Types::ClassObjectType.new('NoMethodError')])
          elsif method && (@_cp_fixed_methods.has_key?(method))
            result = @_cp_fixed_methods[method]
            new_value = result
            new_type = Utilities.type_for(result)
            raised = Frequency::NEVER
            raise_type = Types::EMPTY
          elsif fixed_arity && !issuper &&
                (special_result, special_type =
                 apply_special_case(instruction, receiver, method_name, *args);
                 special_result != INAPPLICABLE)
            new_value = special_result
            new_type = special_type
            raised = Frequency::NEVER
            raise_type = Types::EMPTY
          elsif components.any? { |arg| arg.value == VARYING }
            new_value = VARYING
            new_type, raised, raise_type = infer_type_and_raising(instruction, receiver, method_name, args, cp_opts)
          # All components constant, and never evaluated before.
          elsif original == UNDEFINED
            if !issuper && method && (method.pure || allow_impure_method?(method))
              arg_array = fixed_arity ? args.map(&:value) : args.value
              block = opts[:block] && opts[:block].value
              new_value, new_type, raised, raise_type = adapt_simulation_of_method(
                  instruction, receiver.value, method, arg_array, block, cp_opts)
            else
              new_value = VARYING
              new_type, raised, raise_type = infer_type_and_raising(instruction, receiver, method_name, args, cp_opts)
            end
          else
            # all components constant, nothing changed, shouldn't happen, but okay
            new_value = original
            new_type = old_type
            raised = instruction.raise_frequency
            raise_type = instruction.raise_type
          end
          # At this point, we should prune raise edges!
          if original != new_value
            target.bind! new_value
            changed = true
          end
          if old_type != new_type
            Laser.debug_puts "-> Return type: #{new_type.inspect}"
            target.inferred_type = new_type
            changed = true
          end
          Laser.debug_puts "-> Raise freq: #{raised.inspect}"
          if raise_type != old_raise_type
            Laser.debug_puts "-> Raise Type: #{raise_type.inspect}"
            instruction.raise_type = raise_type
            raise_changed = true
          end
          [changed, raised, raise_changed]
        end

        # Runs method call simulation from the Simulation modules, and adapts
        # the output for consumption by constant propagation.
        def adapt_simulation_of_method(insn, receiver, method, args, block, opts)
          opts = Simulation::DEFAULT_SIMULATION_OPTS.merge(opts)
          opts.merge!(current_block: insn.block)
          begin
            new_value = simulate_call_dispatch(receiver, method, args, block, opts)
            new_type = Utilities.type_for(new_value)
            raised = Frequency::NEVER
            raise_type = Types::EMPTY
          rescue Simulation::ExitedAbnormally => err
            new_value = UNDEFINED
            new_type = Types::TOP
            raised = Frequency::ALWAYS
            raise_type = Types::UnionType.new([Types::ClassObjectType.new(err.error.class.name)])
          end
          [new_value, new_type, raised, raise_type]
        end

        def infer_type_and_raising(instruction, receiver, method_name, args, opts)
          begin
            type, raise_freq, raise_type = cpa_call_properties(
                receiver, method_name, args, instruction, opts)
          rescue TypeError => err
            type = Types::TOP
            raise_freq = Frequency::ALWAYS
            raise_type = Types::UnionType.new([Types::ClassObjectType.new('TypeError')])
            Laser.debug_puts("No method named #{method_name} with matching types was found")
            instruction.node.add_error(NoMatchingTypeSignature.new(
                "No method named #{method_name} with matching types was found", instruction.node))
          end
          [type, raise_freq, raise_type]
        end

        # Calculates all possible return types, raise types, and the raise
        # frequency for a method call using CPA.
        def cpa_call_properties(receiver, method, args, instruction, opts)
          ignore_privacy, block = instruction.ignore_privacy, instruction.block_operand
          dispatches = cpa_dispatches(receiver, instruction, method, opts)
          cartesian = calculate_possible_templates(dispatches, args, block)
          result = cpa_for_templates(dispatches, cartesian)
          raise_result, raise_type = raisability_for_templates(dispatches, cartesian, ignore_privacy)
          if result.empty?
            raise TypeError.new("No methods named #{method} with matching types were found.")
          end
          [Types::UnionType.new(result), raise_result, raise_type]
        end

        # Calculates all possible (self_type, dispatches) pairs for a call.
        def cpa_dispatches(receiver, instruction, method, opts)
          if instruction.type == :call || instruction.type == :call_vararg
            receiver.expr_type.member_types.map do |type|
              [type, type.matching_methods(method)]
            end
          else
            dispatches = instruction.possible_methods(opts)
            receiver.expr_type.member_types.map do |type|
              [type, dispatches]
            end
          end
        end

        # Calculates the set of methods potentially invoked in dynamic dispatch,
        # and the set of all possible argument type combinations.
        def calculate_possible_templates(possible_dispatches, args, block)
          if Bindings::Base === args && Types::TupleType === args.expr_type
            cartesian_parts = args.element_types
            empty = cartesian_parts.empty?
          elsif Bindings::Base === args && Types::UnionType === args.expr_type &&
                Types::TupleType === args.expr_type.member_types.first
            cartesian_parts = args.expr_type.member_types.first.element_types.map { |x| [x] }
            empty = cartesian_parts.empty?
          else
            cartesian_parts = args.map(&:expr_type).map(&:member_types).map(&:to_a)
            empty = args.empty?
          end
          if empty && !block
            cartesian = [ [Types::NILCLASS] ]
          else
            if block
            then cartesian_parts << block.expr_type.member_types.to_a
            else cartesian_parts << [Types::NILCLASS]
            end
            cartesian = cartesian_parts[0].product(*cartesian_parts[1..-1])
          end
          cartesian
        end

        # Calculates the CPA-based return type of a dynamic call.
        def cpa_for_templates(possible_dispatches, cartesian)
          result = Set.new
          possible_dispatches.each do |self_type, methods|
            result |= methods.map do |method|
              cartesian.map do |*type_list, block_type|
                begin
                  method.return_type_for_types(self_type, type_list, block_type)
                rescue TypeError => err
                  Laser.debug_puts("Invalid argument types found.")
                  nil
                end
              end.compact
            end.flatten
          end
          result
        end
        
        # TODO(adgar): Optimize this. Use lattice-style expression of raisability
        # until types need to be added too.
        def raisability_for_templates(possible_dispatches, cartesian, ignore_privacy)
          raise_type = Types::EMPTY
          seen_public = seen_private = seen_raise = seen_succeed = seen_any = seen_missing = false
          seen_valid_arity = seen_invalid_arity = false
          arity = cartesian.first.size - 1  # -1 for block arg
          possible_dispatches.each do |self_type, methods|
            seen_any = true if methods.size > 0 && !seen_any
            seen_missing = true if methods.empty? && !seen_missing
            methods.each do |method|
              if !seen_valid_arity && method.valid_arity?(arity)
                seen_valid_arity = true
              end
              if !seen_invalid_arity && !method.valid_arity?(arity)
                seen_invalid_arity = true
              end
                
              cartesian.each do |*type_list, block_type|
                raise_frequency = method.raise_frequency_for_types(self_type, type_list, block_type)
                if raise_frequency > Frequency::NEVER
                  seen_raise = true
                  raise_type = raise_type | method.raise_type_for_types(self_type, type_list, block_type)
                end
                seen_succeed = raise_frequency < Frequency::ALWAYS if !seen_succeed
                if !ignore_privacy
                  self_type.possible_classes.each do |self_class|
                    if !seen_public
                      seen_public = (self_class.visibility_for(method.name) == :public)
                    end
                    if !seen_private
                      seen_private = (self_class.visibility_for(method.name) != :public)
                    end
                  end
                end
              end
            end
          end

          if seen_any
            fails_lookup = seen_missing ? Frequency::MAYBE : Frequency::NEVER
            fails_privacy = if ignore_privacy
                            then Frequency::NEVER
                            else Frequency.for_samples(seen_private, seen_public)
                            end
            failed_arity = Frequency.for_samples(seen_invalid_arity, seen_valid_arity)
            if fails_privacy == Frequency::ALWAYS
              raise_type = ClassRegistry['NoMethodError'].as_type
            elsif failed_arity == Frequency::ALWAYS
              raise_type = ClassRegistry['ArgumentError'].as_type
            else
              if fails_lookup > Frequency::NEVER || fails_privacy > Frequency::NEVER
                raise_type |= ClassRegistry['NoMethodError'].as_type
              end
              if failed_arity > Frequency::NEVER
                raise_type |= ClassRegistry['ArgumentError'].as_type
              end
            end
            raised = Frequency.for_samples(seen_raise, seen_succeed)
            raise_freq = [fails_privacy, raised, fails_lookup, failed_arity].max
          else
            raise_freq = Frequency::ALWAYS  # no method!
            raise_type = ClassRegistry['NoMethodError'].as_type
          end
          [raise_freq, raise_type]
        end

        # Evaluates the instruction, and if the constant value is lowered,
        # then return true. Otherwise, return false.
        def constant_propagation_evaluate(instruction)
          target = instruction[1] || cp_cell_for(instruction)
          original = target.value
          old_type = target.inferred_type
          changed = false
          case instruction.type
          when :assign
            rhs = instruction[2]
            if Bindings::Base === rhs
              # temporary <- temporary
              new_value = rhs.value
              new_type = rhs.inferred_type
            else
              # temporary <- constant
              new_value = rhs
              new_type = Utilities.type_for(rhs)
            end
          when :phi
            components = instruction[2..-1]
            if components.any? { |var| var.value == VARYING }
              new_value = VARYING
              new_type  = Types::UnionType.new(components.select { |c| c.value != UNDEFINED }.map(&:inferred_type).compact.uniq)
            else
              possible_values = components.map(&:value).uniq - [UNDEFINED]
              Laser.debug_puts("CP_Phi(#{instruction.inspect}, #{possible_values.inspect})")
              if possible_values == []
                new_value = UNDEFINED
                new_type  = nil
              elsif possible_values.size == 1
                new_value = possible_values.first
                new_type  = Utilities.type_for(new_value)
              else
                new_value = VARYING
                new_type  = Types::UnionType.new(components.select { |c| c.value != UNDEFINED }.map(&:inferred_type).compact.uniq)
              end
            end
          when :super, :super_vararg
            new_value = VARYING
            new_type = Types::TOP
          else
            raise ArgumentError("Invalid evaluate instruction evaluation type: #{instruction.type}")
          end
          if original != new_value
            target.bind! new_value
            changed = true
          end
          if old_type != new_type
            target.inferred_type = new_type
            changed = true
          end
          changed
        end
        
        def is_numeric?(temp)
          temp.value != UNDEFINED && Types.subtype?(temp.inferred_type, 
              Types::ClassType.new('Numeric', :covariant))
        end
        
        def uses_method?(temp, method)
          temp.value != UNDEFINED && temp.expr_type.matching_methods(method.name) == [method]
        end
        
        # TODO(adgar): Add typechecking. Forealz.
        def apply_special_case(instruction, receiver, method_name, *args)
          if method_name == :*
            # 0 * n == 0
            # n * 0 == 0
            if (receiver.value == 0 && is_numeric?(args.first)) ||
               (args.first.value == 0 && is_numeric?(receiver))
              return [0, Types::FIXNUM]
            elsif (args.first.value == 0 &&
                   uses_method?(receiver, ClassRegistry['String'].instance_method(:*)))
              return ['', Types::STRING]
            elsif (args.first.value == 0 &&
                   receiver.expr_type.member_types.all? { |t|
                     Types::TupleType === t || t.matching_methods(:*) == [ClassRegistry['Array'].instance_method(:*)]
                   })
              return [[], Types::ARRAY]
            end
          elsif method_name == :**
            # n ** 0 == 1
            if args.first.value == 0 && is_numeric?(receiver)
              return [1, Types::FIXNUM]
            # 1 ** n == 1
            elsif receiver.value == 1 && is_numeric?(args.first)
              return [1, Types::FIXNUM]
            end
          elsif method_name == :===
            if LaserModule === receiver.value && args.first != UNDEFINED
              instance_type = args.first.expr_type
              module_type = Types::ClassType.new(receiver.value.path, :covariant)
              result = Types.subtype?(instance_type, module_type)
              if result
                return [true, Types::TRUECLASS]
              elsif !(Types.overlap?(instance_type, module_type))
                return [false, Types::FALSECLASS]
              end
            end
          elsif method_name == :instance_variable_get
            if args.first.value != UNDEFINED && args.first.value != VARYING
              klass = LaserObject === receiver.value ? receiver.value.normal_class : receiver.expr_type.possible_classes.first
              ivar = klass.instance_variable(args.first.value)
              ivar.uses.add(instruction)
              return [VARYING, ivar.expr_type]
            end
          elsif method_name == :instance_variable_set
            if args.first.value != UNDEFINED && args.first.value != VARYING
              klass = LaserObject === receiver.value ? receiver.value.normal_class : receiver.expr_type.possible_classes.first
              ivar = klass.instance_variable(args.first.value)
              unless Types.subtype?(args[1].expr_type, ivar.expr_type)
                ivar.inferred_type = Types::UnionType.new([args[1].expr_type, ivar.expr_type])
              end
              return [args[1].value, ivar.expr_type]
            end
          elsif receiver == ClassRegistry['Laser#Magic'].binding
            magic_result, magic_type = cp_magic(instruction, method_name, *args)
            if magic_result != INAPPLICABLE
              return [magic_result, magic_type]
            end
          elsif (receiver.value == ClassRegistry['Proc'] && method_name == :new) ||
                ((method_name == :block_given? || method_name == :iterable?) &&
                 (uses_method?(receiver, ClassRegistry['Kernel'].instance_method(:block_given?)))) # and check no block
            return cp_magic(instruction, :current_block)
          elsif receiver.value == ClassRegistry['Array'] && method_name == :[]
            if args.all? { |arg| arg.value != UNDEFINED }
              tuple_type = Types::TupleType.new(args.map(&:expr_type))
              if args.all? { |arg| arg.value != VARYING }
                return [args.map(&:value), tuple_type]
              else
                return [VARYING, tuple_type]
              end
            end
          elsif receiver.value == ClassRegistry['Array'] && method_name == :new
            if args.all? { |arg| arg.value != UNDEFINED }
              if args.size == 0
                return [[], Types::TupleType.new([])]
              elsif args.size == 1 && Types::equal(Types::ARRAY, args.first.expr_type)
                return [args.first.value, args.first.expr_type]
              else
                # TODO(adgar): add integer, val, and integer, block case
              end
            end
          elsif receiver.expr_type.member_types.size == 1 &&
                Types::TupleType === receiver.expr_type.member_types.first
            tuple_type = receiver.expr_type.member_types.first
            # switch on method object
            case tuple_type.matching_methods(method_name)[0]
            when ClassRegistry['Array'].instance_method(:size)
              size = tuple_type.size
              return [size, Utilities.type_for(size)]
            end
          elsif method_name == :+
            if receiver.value != VARYING && receiver.value != UNDEFINED &&
               Utilities.normal_class_for(receiver.value) == ClassRegistry['Array'] &&
               args[0].value == VARYING && args[0].expr_type.member_types.all? { |t| Types::TupleType === t }
              constant, tuple = receiver, args[0]
            elsif args[0].value != VARYING && args[0].value != UNDEFINED &&
                  Utilities.normal_class_for(args[0].value) == ClassRegistry['Array'] &&
                  receiver.value == VARYING && 
                  receiver.expr_type.member_types.all? { |t| Types::TupleType === t }
              constant, tuple = args[0], receiver
            end
            if constant
              constant_types = constant.value.map { |v| Utilities.type_for(v) }
              new_types = tuple.expr_type.member_types.map do |tuple_type|
                Types::TupleType.new(constant_types + tuple_type.element_types)
              end
              return [VARYING, Types::UnionType.new(new_types)]
            end
          end
          [INAPPLICABLE, Types::EMPTY]
        end
        
        def allow_impure_method?(method)
          method == ClassRegistry['Module'].instance_method(:const_get)
        end
        
        def cp_magic(instruction, method_name, *args)
          case method_name
          when :current_self
            return [VARYING, real_self_type]
          when :current_argument
            return [VARYING, real_formal_type(args[0].value)]
          when :current_argument_range
            if bound_argument_types?
              tuple_args = ((args[0].value)...(args[0].value + args[1].value)).map do |num|
                real_formal_type(num)
              end
              return [VARYING, Types::TupleType.new(tuple_args)]
            else
              return [VARYING, Types::ARRAY]
            end
          when :current_arity
            if bound_argument_types?
              return [bound_arity, Types::FIXNUM]
            else
              return [VARYING, Types::FIXNUM]
            end
          when :current_block
            if real_block_type == Types::NILCLASS
              return [nil, Types::NILCLASS]
            else
              return [VARYING, real_block_type]
            end
          when :current_exception
            return [VARYING, Types::EMPTY]
          when :get_just_raised_exception
            # Actually assigned to by the call's raisability-inference.
            # return current state.
            result_holder = instruction[1]
            return [result_holder.value, result_holder.expr_type]
          when :get_global
            global = Scope::GlobalScope.lookup(args[0].value)
            global.uses.add(instruction)
            return [VARYING, global.expr_type]
          when :set_global
            if args[1].value != UNDEFINED
              global = Scope::GlobalScope.lookup(args[0].value)
              unless Types.subtype?(args[1].expr_type, global.expr_type)
                global.inferred_type = Types::UnionType.new([args[1].expr_type, global.expr_type])
              end
              return [VARYING, global.expr_type]
            end
          when :responds?
            name = args[1].value
            seen_yes = seen_no = false
            args[0].expr_type.possible_classes.each do |klass|
              if klass.instance_method(name)
              then seen_yes = true; break if seen_no
              else seen_no = true; break if seen_yes
              end
            end
            if seen_yes && !seen_no
              return [true, Types::TRUECLASS]
            elsif !seen_yes && seen_no
              return [false, Types::FALSECLASS]
            elsif seen_yes && seen_no
              return [VARYING, Types::BOOLEAN]
            else  # receiver's type is empty. YAGNI?
              return [false, Types::FALSECLASS]
            end
          end
          [INAPPLICABLE, nil]
        end

        def validate_tuple_expectation(instruction)
          expect_type, val, array = instruction[2..-1]
          return if array.value == UNDEFINED
          node = instruction.node
          array.expr_type.member_types.each do |type|
            if Types::TupleType === type
              if type.size < val && expect_type == :==
                node.add_error(UnassignedLHSError.new('LHS never assigned - defaults to nil', node))
              elsif type.size <= val && expect_type == :>
                node.add_error(UnassignedLHSError.new('LHS splat is always empty ([]) - not useful', node))
              elsif type.size > val && expect_type == :==
                node.add_error(DiscardedRHSError.new('RHS value being discarded', node))
              elsif type.size >= val && expect_type == :<
                node.add_error(DiscardedRHSError.new('RHS splat expanded and then discarded', node))
              end
            end
          end
        end
      end  # ConstantPropagation
    end  # ControlFlow
  end  # Analysis
end  #
