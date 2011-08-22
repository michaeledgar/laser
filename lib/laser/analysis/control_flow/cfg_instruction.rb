require 'set'
module Laser
  module Analysis
    module ControlFlow
      class Instruction < BasicObject
        attr_reader :node, :block, :body, :ignore_privacy
        attr_accessor :raise_frequency, :raise_type
        def initialize(body, opts={})
          @body = body
          @node = opts[:node]
          @block = opts[:block]
          @raise_frequency = :unknown
          @raise_type = Types::EMPTY
          @ignore_privacy = opts[:ignore_privacy]
          @true_successor = @false_successor = nil
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

        def deep_dup(temp_lookup, opts={})
          new_body = @body[1..-1].map do |arg|
            case arg
            when Bindings::ConstantBinding then arg
            when Bindings::Base then temp_lookup[arg]
            when ::Hash
              if arg[:block]
              then arg.merge(block: temp_lookup[arg[:block]])
              else arg
              end
            else arg.dup rescue arg
            end
          end
          
          new_body.unshift(self[0])  # self[0] always symbol
          new_opts = {node: @node, block: temp_lookup[@block], ignore_privacy: @ignore_privacy}.merge(opts)
          self.class.new(new_body, new_opts)
        end

        def method_missing(meth, *args, &blk)
          @body.send(meth, *args, &blk)
        end

        def method_call?
          [:call, :call_vararg, :super, :super_vararg].include?(type)
        end

        def require_method_call
          unless method_call?
            raise TypeError.new("#possible_methods is not defined on #{type} instructions.")
          end
        end

        def require_branch(method_needed='the requested operation')
          unless type == :branch
            raise TypeError.new("#{method_needed} is not defined on #{type} instructions.")
          end
        end

        def true_successor
          require_branch('#true_successor')
          calculate_branch_successors
          return @true_successor
        end

        def false_successor
          require_branch('#false_successor')
          calculate_branch_successors
          return @false_successor
        end
        
        def calculate_branch_successors
          return if @true_successor
          successors = block.successors.to_a
          if successors[0].name == self[2]
          then @true_successor, @false_successor = successors[0..1]
          else @false_successor, @true_successor = successors[0..1]
          end
        end

        def possible_public_methods
          require_method_call
          if type == :call || type == :call_vararg
            if Bindings::ConstantBinding === self[2]
              [self[2].value.singleton_class.public_instance_method(self[3])].compact
            elsif LaserObject === self[2].value
              [self[2].value.klass.public_instance_method(self[3])].compact
            else
              self[2].expr_type.public_matching_methods(self[3])
            end
          else
            #TODO(adgar): SUPER
          end
        end

        def possible_methods(opts)
          require_method_call
          if type == :call || type == :call_vararg
            if Bindings::ConstantBinding === self[2]
              [self[2].value.singleton_class.instance_method(self[3])].compact
            elsif LaserObject === self[2].value
              [self[2].value.klass.instance_method(self[3])].compact
            else
              self[2].expr_type.matching_methods(self[3])
            end
          else
            [opts[:method].super_method]
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

        def block_operand
          ::Hash === last ? last[:block] : nil
        end
        
        def replace_block_operand(new_block)
          last[:block] = new_block
        end

        # Gets all bindings that are operands in this instruction
        def operands
          self[operand_range].select { |x| Bindings::Base === x && x != Bootstrap::VISIBILITY_STACK }
        end
        
        # Replaces the operands with a new list. Used by SSA renaming.
        def replace_operands(new_operands)
          # splice in new operands: replace bindings with bindings.
          index = operand_range.begin
          while new_operands.any? && index < @body.size
            if Bindings::Base === self[index] && self[index] != Bootstrap::VISIBILITY_STACK 
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
          when :declare
            case self[1]
            when :alias then 2..-1
            when :expect_tuple_size then 4..-1
            end
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