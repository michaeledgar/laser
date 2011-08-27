module Laser
  module Analysis
    module ControlFlow
      # Finds the properties of how the code yields to a block argument.
      # Should not be used on top-level code, naturally.
      module AliasAnalysis
        def weak_local_aliases_for(initial, value_to_match = nil)
          good_blocks = reachable_vertices
          aliases = initial
          aliases.merge(value_aliases(value_to_match))
          worklist = aliases.map(&:uses).inject(:|)
          until worklist.empty?
            use = worklist.pop
            if use[1] && good_blocks.include?(use.block)
              if use[1] != :alias && aliases.add?(use[1])
                worklist.merge(use[1].uses)
              elsif use[1] == :alias && aliases.add?(use[2])
                worklist.merge(use[2].uses)
              end
            end
          end
          aliases
        end
        
        def value_aliases(value_to_match)
          value_to_match ? all_variables.select { |var| var.value == value_to_match} : []
        end
      end
    end  # ControlFlow
  end  # Analysis
end  #
