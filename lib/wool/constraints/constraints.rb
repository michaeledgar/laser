require 'set'
module Wool
  class Type
    extend ModuleExtensions
    attr_accessor_with_default :constraints, Set.new
    def initialize(constraints)
      self.constraints |= Set.new(constraints)
    end
  end
  
  module Constraints
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

    class SelfTypeConstraint < TypeConstraint
      acts_as_struct :scope
      
      def signature
        {scope: scope}
      end
    end
    
    class ClassConstraint < Base
      acts_as_struct :class_name, :variance
      
      def signature
        {class_name: class_name, variance: variance}
      end
    end

    class GenericClassConstraint < ClassConstraint
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
  end
end
