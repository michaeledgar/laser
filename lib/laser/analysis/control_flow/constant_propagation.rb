module Laser
  module SexpAnalysis
    module ControlFlow
      # Sparse Conditional Constant Propagation: Wegman and Zadeck
      # Love those IBMers
      # Using Morgan's implementation though.
      module ConstantPropagation
        attr_reader :constants

        UNDEFINED = Object.new
        VARYING = Object.new
        INAPPLICABLE = Object.new
        # Only public method: mutably turns the CFG into a constant-propagated
        # one. Each binding will have a value assigned to it afterward: either
        # the constant, as a Ruby object (or a proxy to one), UNDEFINED, or VARYING.
        def perform_constant_propagation
          initialize_constant_propagation
          visited = Set.new
          worklist = Set.new
          blocklist = Set[self.enter]
          while worklist.any? || blocklist.any?
            while worklist.any?
              constant_propagation_for_instruction(
                  worklist.pop, blocklist, worklist)
            end
            while blocklist.any?
              constant_propagation_for_block(
                  blocklist.pop, visited, blocklist, worklist)
            end
          end
          all_variables.select do |variable|
            variable.value != VARYING && variable.value != UNDEFINED
          end.each do |constant|
            @constants[constant] = constant.value
          end
        end

        # Initializes the variables, formals, and edges for constant propagation.
        # Morgan, p. 201
        def initialize_constant_propagation
          all_variables.each do |temp|
            temp.bind! UNDEFINED
            temp.inferred_type = nil
          end
          @formals.each do |formal|
            temporary = @formal_map[formal]
            temporary.bind! VARYING
            temporary.inferred_type = Types::TOP
          end
          vertices.each do |block|
            block.successors.each do |succ|
              remove_flag(block, succ, ControlFlowGraph::EDGE_EXECUTABLE)
            end
          end
        end
        private :initialize_constant_propagation

        # Simulates a block. As we know, phi nodes execute simultaneously
        # and immediately upon block entry, so first we check phi nodes to
        # see if they form a constant. This happens unconditionally, as
        # phi nodes must be checked repeatedly.
        #
        # Then, if the block hasn't been visited before, simulate the normal
        # instructions, and mark it so it is not visited again.
        #
        # Morgan, p.200
        def constant_propagation_for_block(block, visited, blocklist, worklist)
          block.phi_nodes.each do |phi_node|
            constant_propagation_for_instruction(
                phi_node, blocklist, worklist)
          end
          if visited.add?(block)
            block.natural_instructions.each do |instruction|
              constant_propagation_for_instruction(
                  instruction, blocklist, worklist)
            end
            if block.fall_through_block?
              block.successors.each do |succ|
                constant_propagation_consider_edge block, succ, blocklist
              end
            end
          end
        end
        private :constant_propagation_for_block
        
        def constant_propagation_for_instruction(instruction, blocklist, worklist)
          if instruction.type == :branch
            constant_propagation_for_branch(instruction, blocklist)
          elsif instruction.type == :jump
            block = instruction.block
            succ = block.successors.first
            constant_propagation_consider_edge block, succ, blocklist
          else
            if constant_propagation_evaluate(instruction)
              instruction.explicit_targets.each do |target|
                @uses[target].each do |use|
                  worklist.add? use
                end
              end
            end
          end
        end
        
        # Examines the branch for newly executable edges, and adds them to
        # the blocklist.
        def constant_propagation_for_branch(instruction, blocklist)
          block = instruction.block
          executable_successors = case instruction[1].value
                                  when VARYING then block.successors
                                  when UNDEFINED then []
                                  when nil, false then [vertex_with_name(instruction[3])]
                                  else [vertex_with_name(instruction[2])]
                                  end

          executable_successors.each do |succ|
            constant_propagation_consider_edge block, succ, blocklist
          end
        end

        def constant_propagation_consider_edge(block, succ, blocklist)
          if !is_executable?(block, succ)
            add_flag(block, succ, ControlFlowGraph::EDGE_EXECUTABLE)
            blocklist << succ
          end
        end

        # Evaluates the instruction, and if the constant value is lowered,
        # then return true. Otherwise, return false.
        def constant_propagation_evaluate(instruction)
          changed = false  # unnecessary, but clarifies intent
          case instruction.type
          when :assign
            lhs, rhs = instruction[1..2]
            if Bindings::GenericBinding === rhs
              # temporary <- temporary
              changed = (lhs.value != rhs.value)
              if changed
                lhs.bind! rhs.value
                lhs.inferred_type = rhs.inferred_type
              end
            else
              # temporary <- constant
              changed = (lhs.value != rhs)
              if changed
                lhs.bind! rhs
                lhs.inferred_type = Types::ClassType.new(rhs.class.name, :invariant)
              end
            end
          when :call
            target, receiver, method_name, *args = instruction[1..-1]
            return false if target.nil?
            opts = Hash === args.last ? args.pop : {}
            components = [receiver, *args]
            if (result = apply_special_arithmetic_case(receiver, method_name, *args)) &&
               result != INAPPLICABLE
              changed = (target.value != result)
              if changed
                target.bind! result
                target.inferred_type = Types::ClassType.new(result.class.name, :invariant)
              end
            elsif components.any? { |arg| arg.value == UNDEFINED }
              changed = false  # cannot evaluate unless all args and receiver are constant
            elsif components.any? { |arg| arg.value == VARYING }
              changed = (target.value != VARYING)
              if changed
                target.bind! VARYING
                target.inferred_type = Types::TOP
              end
            else
              # all components constant.
              changed = (target.value == UNDEFINED)  # varying impossible here
              # TODO(adgar): CONSTANT BLOCKS
              if changed && (!opts || !opts[:block]) # && method.is_pure
                # check purity
                type = receiver.expr_type
                method = type.matching_methods(method_name).first
                if method && method.pure
                  result = receiver.value.send(method_name, *args.map(&:value))
                  target.bind!(result)
                  target.inferred_type = Types::ClassType.new(result.class.name, :invariant)
                else
                  target.bind! VARYING
                  target.inferred_type = Types::TOP
                end
              end
            end
          when :phi
            target, *components = instruction[1..-1]
            original = target.value
            if components.any? { |var| var.value == VARYING }
              new_value = VARYING
              new_type  = Types::TOP
            else
              possible_values = components.map(&:value).uniq - [UNDEFINED]
              if possible_values == []
                new_value = UNDEFINED
                new_type  = nil
              elsif possible_values.size == 1
                new_value = possible_values.first
                new_type  = Types::ClassType.new(new_value.class.name, :invariant)
              else
                new_value = VARYING
                new_type  = Types::UnionType.new(components.map(&:inferred_type).compact.uniq)
              end
            end
            changed = original != new_value
            if changed
              target.bind! new_value
              target.inferred_type = new_type
            end
          when :lambda
            # lambdas are constant if they close over zero non-constant variables.
            # I assume pessimistically that they always do, for now.
            target = instruction[1]
            changed = (target.value != VARYING)  # assume closure on non-constant here
            if changed
              target.bind! VARYING
              target.inferred_type = Types::ClassType.new('Proc', :invariant)
            end
          when :call_vararg, :super, :super_vararg, :yield
            target = instruction[1]
            return false if target.nil?
            changed = (target.value != VARYING)  # assume closure on non-constant here
            if changed
              target.bind! VARYING
              target.inferred_type = Types::TOP
            end
          end
          changed
        end
        
        # TODO(adgar): Add typechecking. Forealz.
        def apply_special_arithmetic_case(receiver, method_name, *args)
          if method_name == :*
            # 0 * n == 0
            # n * 0 == 0
            if (receiver.value == 0 && args.first.value != UNDEFINED &&
                Types.subtype?(args.first.inferred_type, Types::ClassType.new('Numeric', :covariant))) ||
               (receiver.value != UNDEFINED && args.first.value == 0 &&
                Types.subtype?(receiver.inferred_type, Types::ClassType.new('Numeric', :covariant)))
              return 0
            end
          elsif method_name == :**
            # n ** 0 == 1
            if args.first.value == 0 && receiver.value != UNDEFINED
              return 1
            # 0 ** n == 0, n != 0
            elsif receiver.value == 0 && args.first.value != UNDEFINED
              return 0
            end
          end
          INAPPLICABLE
        end
      end  # ConstantPropagation
    end  # ControlFlow
  end  # SexpAnalysis
end  #