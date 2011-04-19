require 'set'
module Laser
  module SexpAnalysis
    module ControlFlow
      class Instruction < BasicObject
        attr_reader :node, :block, :body
        def initialize(body, opts={})
          @body = body
          @node = opts[:node]
          @block = opts[:block]
        end

        def type
          @body[0]
        end

        def class
          Instruction
        end

        def ==(other)
          @body == other.body
        end

        def method_missing(meth, *args, &blk)
          @body.send(meth, *args, &blk)
        end

        def simulate!
          case type
          when :assign
            lhs, rhs = self[1..2]
            if Bindings::GenericBinding === rhs
              lhs.bind! rhs.value
              lhs.inferred_type = rhs.inferred_type
            else
              # literal assignment e.g. fixnum/float/string
              lhs.bind! rhs
              lhs.inferred_type = Types::ClassType.new(rhs.class.name, :invariant)
            end
          end
        end

        def method_call?
          [:call, :call_vararg, :super, :super_vararg].include?(type)
        end

        def require_method_call
          unless method_call?
            raise TypeError.new("#possible_methods is not defined on #{type} instructions.")
          end
        end

        def possible_methods
          require_method_call
          if type == :call || type == :call_vararg
            if Bindings::ConstantBinding === self[2]
              [self[2].value.singleton_class.instance_methods[self[3].to_s]]
            elsif LaserObject === self[2].value
              [self[2].value.klass.instance_methods[self[3].to_s]]
            else
              self[2].expr_type.matching_methods(self[3])
            end
          else
            #TODO(adgar): SUPER
          end
        end

        # Gets all bindings that are explicitly set in this instruction (no aliasing
        # concerns)
        def explicit_targets
          case self[0]
          when :assign, :call, :call_vararg, :super, :super_vararg, :lambda, :phi
            self[1] ? ::Set[self[1]] : ::Set[]
          else
            ::Set[]
          end
        end
  
        # Gets all bindings that are operands in this instruction
        def operands
          self[operand_range].select { |x| Bindings::GenericBinding === x}
        end
        
        # Replaces the operands with a new list. Used by SSA renaming.
        def replace_operands(new_operands)
          # splice in new operands: replace bindings with bindings.
          index = operand_range.begin
          while new_operands.any? && index < @body.size
            if Bindings::GenericBinding === self[index]
              self[index] = new_operands.shift
            end
            index += 1
          end
        end

        # Replaces a target of the instruction. Used by SSA renaming.
        # Currently, all instructions only have at most 1 target.
        def replace_target(original_target, new_target)
          if self[1] == original_target
            self[1] = new_target
          else
            raise ArgumentError.new("#{original_target.inspect} is not a "+
                                    "target of #{self.inspect}")
          end
        end

       private

        def operand_range
          case self[0]
          when :assign, :call_vararg, :super, :super_vararg, :lambda, :phi
            2..-1
          when :call
            # check for hardcoded call on a constant class. Used by literals.
            if Bindings::ConstantBinding === self[2]
            then 3..-1
            else 2..-1
            end
          else 1..-1
          end
        end
      end
    end
  end
end