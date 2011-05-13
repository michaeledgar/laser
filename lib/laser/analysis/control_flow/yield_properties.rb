module Laser
  module SexpAnalysis
    module ControlFlow
      # Finds the properties of how the code yields to a block argument.
      # Should not be used on top-level code, naturally.
      module YieldProperties
        def find_yield_properties
          without_yield = dup
          with_yield = dup
          kernel_method_to_fix = ClassRegistry['Kernel'].instance_methods['block_given?']
          magic_method_to_fix = ClassRegistry['Laser#Magic'].singleton_class.instance_methods['current_block']
          
          without_yield.perform_constant_propagation(
              fixed_methods: {kernel_method_to_fix => false, magic_method_to_fix => nil})

          without_yield.prune_unexecuted_blocks
          with_yield.prune_unexecuted_blocks

          ever_yields = !!with_yield.vertex_with_name(ControlFlowGraph::YIELD_POSTDOMINATOR_NAME)
          # shortcut that ignores the possibility of foolish
          yields_without_block = !!without_yield.vertex_with_name(ControlFlowGraph::YIELD_POSTDOMINATOR_NAME)
          @yield_type = case [ever_yields, yields_without_block]
                        when [true, true] then :required
                        when [true, false] then :optional
                        when [false, true] then :foolish
                        when [false, false] then :ignored
                        end
        end
      end
    end  # ControlFlow
  end  # SexpAnalysis
end  #
