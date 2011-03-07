module Laser
  module SexpAnalysis
    module ControlFlow
      # Can't use the < DelegateClass(Array) syntax because of code reloading.
      BasicBlock = DelegateClass(Array)
      BasicBlock.class_eval do
        attr_reader :name, :instructions
        def initialize(name)
          @name = name
          @instructions = []
          super(@instructions)
        end

        def ==(other)
          name == other.name
        end
        
        def equals?(other)
          name == other.name
        end

        def hash
          name.hash
        end

        alias to_s name
        alias leader first
      end
    end
  end
end