module Laser
  module SexpAnalysis
    module ControlFlow
      # Finds the properties of how the code yields to a block argument.
      # Should not be used on top-level code, naturally.
      module AliasAnalysis
        def weak_local_aliases_for(var)
          aliases = ::Set[var]
          worklist = @uses[var]
          until worklist.empty?
            use = worklist.pop
            # target of insn is always insn[1]
            if use[1] && aliases.add?(use[1])
              worklist.merge(@uses[use[1]])
            end
          end
          aliases
        end
      end
    end  # ControlFlow
  end  # SexpAnalysis
end  #
