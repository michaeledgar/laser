module Laser
  module SexpAnalysis
    module ControlFlow
      # Finds the properties of how the code yields to a block argument.
      # Should not be used on top-level code, naturally.
      module AliasAnalysis
        def weak_local_aliases_for(var)
          aliases = ::Set[var]
          worklist = var.uses 
          until worklist.empty?
            use = worklist.pop
            # target of insn is always insn[1]
            if use[1] && aliases.add?(use[1])
              worklist.merge(use[1].uses)
            end
          end
          aliases
        end
      end
    end  # ControlFlow
  end  # SexpAnalysis
end  #
