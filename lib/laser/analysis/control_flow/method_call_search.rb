module Laser
  module SexpAnalysis
    module ControlFlow
      # Finds the properties of how the code yields to a block argument.
      # Should not be used on top-level code, naturally.
      module MethodCallSearch
        def find_method_calls(method_to_find)
          possible_calls = []
          reachable_vertices do |block|
            block.instructions.each do |insn|
              cur_insn = insn
              if (insn.type == :call || insn.type == :call_vararg)
                # check if method could be from insn receiver
                if insn.possible_methods.include?(method_to_find)
                  possible_calls << insn
                end
              end
            end
          end
          possible_calls
        end
      end
    end  # ControlFlow
  end  # SexpAnalysis
end  #

