module Laser
  module SexpAnalysis
    module ControlFlow
      # Finds the properties of how the code yields to a block argument.
      # Should not be used on top-level code, naturally.
      module YieldProperties
        def find_yield_properties
          kernel_method_to_fix = ClassRegistry['Kernel'].
              instance_method('block_given?')
          proc_method_to_fix   = ClassRegistry['Proc'].singleton_class.
              instance_method('new')
          magic_method_to_fix  = ClassRegistry['Laser#Magic'].singleton_class.
              instance_method('current_block')
          
          # Calculate the "no block provided" case
          without_yield = dup
          without_yield.bind_block_type(Types::NILCLASS)
          without_yield.perform_constant_propagation(
              fixed_methods: { kernel_method_to_fix => false,
                               proc_method_to_fix   => nil })
          without_yield.kill_unexecuted_edges

          weak_without_calls = without_yield.potential_block_calls
          yield_pd = without_yield.vertex_with_name(
              ControlFlowGraph::YIELD_POSTDOMINATOR_NAME)
          has_yield_pd = yield_pd && yield_pd.real_predecessors.size > 0
          yields_without_block = has_yield_pd || weak_without_calls.size > 0

          # Calculate the "has block provided" case
          with_yield = dup
          with_yield.bind_block_type(Types::PROC)
          fake_block = proc { |*args| }
          with_yield.perform_constant_propagation(
              fixed_methods: { kernel_method_to_fix => true,
                               magic_method_to_fix  => fake_block,
                               proc_method_to_fix   => fake_block})
          with_yield.kill_unexecuted_edges
          weak_with_calls = with_yield.potential_block_calls(fake_block)
          yields_with_block = weak_with_calls.size > 0

          @yield_type = compute_yield_type(yields_with_block, yields_without_block)
          @yield_arity = calculate_yield_arity(weak_with_calls)
        end

        def compute_yield_type(with_block, without_block)
          case [with_block, without_block]
          when [true, true] then :required
          when [true, false] then :optional
          when [false, true] then :foolish
          when [false, false] then :ignored
          end
        end

        def calculate_yield_arity(calls)
          yield_arity = Set.new
          calls.each do |call|
            case call.type
            when :call then yield_arity << (call.size - 5)
            when :call_vararg then yield_arity << (0..Float::INFINITY)
            end
          end
          yield_arity
        end

        def initial_block_aliases
          proc_new_calls = find_method_calls(
              ClassRegistry['Proc'].singleton_class.instance_method('new'))
          registers = proc_new_calls.map { |insn| insn[1] }
          initial_aliases = Set.new(registers)
          initial_aliases.add(block_register)
        end

        def potential_block_calls(block_value = nil)
          aliases = weak_local_aliases_for(initial_block_aliases, block_value)
          calls = []
          reachable_vertices do |block|
            block.instructions.each do |insn|
              if (insn.type == :call || insn.type == :call_vararg) &&
                 insn[3] == :call && aliases.include?(insn[2])
                calls << insn
              elsif aliases.include?(insn.block_operand)
                insn.possible_methods.each do |method|
                  yield_type = method.yield_type
                  if block_value.nil? && (yield_type == :required || yield_type == :foolish)
                    calls << insn
                    break
                  elsif !block_value.nil? && (yield_type == :required || yield_type == :optional)
                    calls << insn
                    break
                  end
                end
              end
            end
          end
          calls
        end
      end
    end  # ControlFlow
  end  # SexpAnalysis
end  #
