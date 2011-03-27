module Laser
  module SexpAnalysis
    module ControlFlow
      # Can't use the < DelegateClass(Array) syntax because of code reloading.
      BasicBlock = DelegateClass(Array)
      BasicBlock.class_eval do
        attr_reader :name, :instructions
        attr_accessor :depth_first_order
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

        def to_s
          " | #{name} | \\n" + instructions.map do |ins|
            opcode = ins.first.to_s
            args = ins[1..-1].map do |arg|
              if Bindings::GenericBinding === arg
              then arg.name
              else arg.inspect
              end
            end
            [opcode, *args].join(', ')
          end.join('\\n')
        end
        alias leader first
      end
    end
  end
end