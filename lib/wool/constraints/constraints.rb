require 'set'
module Wool
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

    class SelfType < TypeConstraint
      acts_as_struct :scope
      
      def signature
        {scope: scope}
      end
    end
    
    class StructuralType < TypeConstraint
      attr_reader :method_name, :arg_constraint_list, :return_constraints
      
      def initialize(method_name, arg_constraint_list, return_constraints)
        @method_name = method_name
        @arg_constraint_list = arg_constraint_list
        @return_constraints = return_constraints
      end
      
      def signature
        {method_name: method_name, arg_constraint_list: arg_constraint_list,
         return_constraints: return_constraints}
      end
    end
    
    class ClassType < Base
      acts_as_struct :class_name, :variance
      
      def signature
        {class_name: class_name, variance: variance}
      end
    end

    class GenericClassType < ClassType
      acts_as_struct :subtype_constraints
      def initialize(*args)
        if args.size <= 2
          super(*args)
        else
          super(*args[0..1])
          @subtype_constraints = args[2]
        end
      end

      def signature
        super.merge(subtype_constraints: subtype_constraints)
      end
    end
    
    # Represents a Tuple: an array of a given, fixed size, with each position
    # in the array possessing a set of constraints.
    class TupleType < TypeConstraint
      attr_reader :element_constraints
      def initialize(element_constraints)
        @element_constraints = element_constraints
      end
      
      def size
        element_constraints.size
      end
      
      def [](idx)
        element_constraints[idx]
      end
      
      def signature
        {element_constraints: element_constraints}
      end
    end
  end
end
