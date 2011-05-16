module Laser
  module SexpAnalysis
    module ControlFlow
      # Finds the properties of how the code yields to a block argument.
      # Should not be used on top-level code, naturally.
      module YieldProperties
        def find_yield_properties
          without_yield = dup
          with_yield = dup
          kernel_method_to_fix = ClassRegistry['Kernel'].instance_method('block_given?')
          magic_method_to_fix  = ClassRegistry['Laser#Magic'].singleton_class.instance_method('current_block')
          
          fake_block = proc { |*args| }
          without_yield.perform_constant_propagation(
              fixed_methods: {kernel_method_to_fix => false, magic_method_to_fix => nil})
          with_yield.perform_constant_propagation(
              fixed_methods: {kernel_method_to_fix => true,  magic_method_to_fix => fake_block})

          without_yield.prune_unexecuted_blocks
          with_yield.prune_unexecuted_blocks

          weak_with_calls = with_yield.potential_block_calls
          ever_yields_with_block = weak_with_calls.size > 0

          weak_without_calls = without_yield.potential_block_calls
          yields_without_block = !!without_yield.vertex_with_name(ControlFlowGraph::YIELD_POSTDOMINATOR_NAME) || weak_without_calls.size > 0

          @yield_type = case [ever_yields_with_block, yields_without_block]
                        when [true, true] then :required
                        when [true, false] then :optional
                        when [false, true] then :foolish
                        when [false, false] then :ignored
                        end
        end

        def potential_block_calls
          aliases = weak_local_aliases_for(block_register)
          calls = []
          vertices.each do |block|
            block.instructions.each do |insn|
              if (insn.type == :call || insn.type == :call_vararg) && insn[3] == :call && aliases.include?(insn[2])
                calls << insn
              end
            end
          end
          calls
        end
      end
    end  # ControlFlow
  end  # SexpAnalysis
end  #
