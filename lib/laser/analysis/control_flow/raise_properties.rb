module Laser
  module SexpAnalysis
    module ControlFlow
      # Finds the properties of how the code yields to a block argument.
      # Should not be used on top-level code, naturally.
      module RaiseProperties
        def find_raise_properties
          find_raise_type
        end
        
        # Finds whether the method raises always, never, or sometimes.
        def find_raise_type
          fail_block = exception_postdominator
          if fail_block.nil?
            @raise_type = :never
          elsif @exit.normal_predecessors.empty?
            @raise_type = :always
          else
            @raise_type = :maybe
          end
        end
      end
    end
  end
end