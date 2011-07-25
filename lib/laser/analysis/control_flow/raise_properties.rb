module Laser
  module Analysis
    module ControlFlow
      # Finds the properties of how the code yields to a block argument.
      # Should not be used on top-level code, naturally.
      module RaiseProperties
        def find_raise_properties
          find_raise_frequency
        end
        
        # Finds whether the method raises always, never, or sometimes.
        def find_raise_frequency
          fail_block = exception_postdominator
          if fail_block.nil? || fail_block.real_predecessors.empty?
            @raise_frequency = Frequency::NEVER
          elsif (@exit.normal_predecessors & @exit.real_predecessors).empty?
            @raise_frequency = Frequency::ALWAYS
          else
            @raise_frequency = Frequency::MAYBE
          end
        end
      end
    end
  end
end