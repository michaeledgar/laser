require 'set'
module Laser
  module Types
    class Base
      extend ActsAsStruct
      
      def hash
        signature.values.map(&:hash).inject(:+)
      end

      def eql?(other)
        self == other
      end

      def ==(other)
        signature.inject(true) {|cur, (name, val)| cur && (val == other.send(name)) }
      end
    end

    class TypeConstraint < Base
    end

    class UnionType < TypeConstraint
      acts_as_struct :member_types
      def initialize(*member_types)
        @member_types = member_types
      end
      
      def signature
        {member_types: member_types}
      end
    end

    class SelfType < TypeConstraint
      acts_as_struct :scope
      
      def signature
        {scope: scope}
      end
    end
    
    class StructuralType < TypeConstraint
      attr_reader :method_name, :argument_types, :return_type
      
      def initialize(method_name, argument_types, return_type)
        @method_name = method_name
        @argument_types = argument_types
        @return_type = return_type
      end
      
      def signature
        {method_name: method_name, argument_types: argument_types,
         return_type: return_type}
      end
    end
    
    class ClassType < Base
      acts_as_struct :class_name, :variance
      
      def possible_classes
        case variance
        when :invariant then ClassRegistry[class_name]
        when :covariant then ClassRegistry[class_name].subset
        when :contravariant then ClassRegistry[class_name].superset
        end
      end
      
      def signature
        {class_name: class_name, variance: variance}
      end
    end

    class GenericType < Base
      acts_as_struct :base_type, :subtypes

      def signature
        super.merge(base_type: base_type, subtypes: subtypes)
      end
    end
    
    # Represents a Tuple: an array of a given, fixed size, with each position
    # in the array possessing a set of constraints.
    class TupleType < TypeConstraint
      attr_reader :element_types
      def initialize(element_types)
        @element_types = element_types
      end
      
      def size
        element_types.size
      end
      
      def [](idx)
        element_types[idx]
      end
      
      def signature
        {element_types: element_types}
      end
    end
  end
end
