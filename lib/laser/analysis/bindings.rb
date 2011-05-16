module Laser
  module SexpAnalysis
    module Bindings
      # This class represents a GenericBinding in Ruby. It may have a known type,
      # class, value (if constant!), and a variety of other details.
      class GenericBinding
        include Comparable
        attr_accessor :name, :annotated_type, :inferred_type, :ast_node, :uses, :definition
        attr_reader :value

        def initialize(name, value)
          @name = name
          @uses = Set.new
          @definition = nil
          @value = :uninitialized
          bind!(value)
        end
        
        def deep_dup
          result = self.class.new(@name, @value)
          result.initialize_dup_deep(self)
          result
        end

        # like initialize_dup, but manually called and deep copy.
        def initialize_dup_deep(other)
          @annotated_type = other.annotated_type.dup if other.annotated_type
          @inferred_type = other.inferred_type.dup if other.inferred_type
          @ast_node = other.ast_node # immutable
          self
        end
        
        def expr_type
          annotated_type || inferred_type || Types::ClassType.new(
              (LaserObject === @value ? @value.klass.path : @value.class.name), :invariant)
        end
      
        def bind!(value)
          if respond_to?(:validate_value)
            validate_value(value)
          end
          @value = value
        end
      
        def <=>(other)
          self.name <=> other.name
        end
      
        def scope
          value.scope
        end
      
        def class_used
          value.klass
        end
      
        def to_s
          inspect
        end
      
        def inspect
          "#<#{self.class.name.split('::').last}: #{name}>"
        end
      end

      class BlockBinding < GenericBinding
        attr_reader :argument_bindings, :ast_body
        def initialize(name, value)
          super(name, value)
        end
        
        def expr_type
          Types::ClassType.new('Proc', :invariant)
        end
      end

      class KeywordBinding < GenericBinding
        private :bind!
      end

      # Constants have slightly different properties in their bindings: They shouldn't
      # be rebound. However.... Ruby allows it. It prints a warning when the rebinding
      # happens, but we should be able to detect this statically. Oh, and they can't be
      # bound inside a method. That too is easily detected statically.
      class ConstantBinding < GenericBinding
        # Require an additional force parameter to rebind a Constant. That way, the user
        # can configure whether rebinding counts as a warning or an error.
        def bind!(val, force=false)
          if @value != :uninitialized && !force
            raise TypeError.new('Cannot rebind a constant binding without const_set')
          end
          super(val)
        end
      end

      # We may want to track # of assignments/reads from local vars, so we should subclass
      # GenericBinding for it.
      class LocalVariableBinding < GenericBinding
      end
      
      class TemporaryBinding < GenericBinding
        def non_ssa_name
          name.rpartition('#').first
        end
      end
      
      class InstanceVariableBinding < GenericBinding
      end

      # Possible extension ideas:
      # - Initial definition point?
      class GlobalVariableBinding < GenericBinding
      end
    
      class ArgumentBinding < GenericBinding
        attr_reader :kind, :default_value_sexp
        def initialize(name, value, kind, default_value = nil)
          super(name, value)
          @kind = kind
          @default_value_sexp = default_value
        end
        
        def deep_dup
          result = self.class.new(@name, @value, @kind, @default_value_sexp)
          result.initialize_dup_deep(self)
        end

        def is_positional?
          :positional == @kind
        end
        def is_optional?
          :optional == @kind
        end
        def is_rest?
          :rest == @kind
        end
        def is_block?
          :block == @kind
        end
      end
    end
  end
end
