module Laser
  module SexpAnalysis
    module Bindings
      # This class represents a GenericBinding in Ruby. It may have a known type,
      # class, value (if constant!), and a variety of other details.
      class GenericBinding
        include Comparable
        attr_accessor :name, :annotated_type
        attr_reader :value

        def initialize(name, value)
          @name = name
          @value = :uninitialized
          bind!(value)
        end
        
        def expr_type
          annotated_type || Types::ClassType.new(@value.klass.path, :covariant)
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
      end
    end
  end
end