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

          call_receiver_group = Hash.new { |h, k| h[k] = [] }
          calls_to_call = with_yield.find_method_calls(ClassRegistry['Proc'].instance_method('call'))
          calls_to_call.each { |insn| call_receiver_group[insn[2].value] << insn }
          guaranteed_calls = call_receiver_group[fake_block]
          possible_calls = call_receiver_group[VARYING]
          [guaranteed_calls, possible_calls]
          ever_yields_with_block = guaranteed_calls.size + possible_calls.size > 0

          weak_without_aliases = without_yield.weak_local_aliases_for(without_yield.block_register)
          calls = []
          without_yield.vertices.each do |block|
            block.instructions.each do |insn|
              if (insn.type == :call || insn.type == :call_vararg) && insn[3] == :call && weak_without_aliases.include?(insn[2])
                calls << insn
              end
            end
          end
          yields_without_block = !!without_yield.vertex_with_name(ControlFlowGraph::YIELD_POSTDOMINATOR_NAME) || calls.size > 0

          @yield_type = case [ever_yields_with_block, yields_without_block]
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
