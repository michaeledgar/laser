module Wool
  module Constraints
    class Base
      extend ActsAsStruct
    end

    class TypeConstraint < Base
    end

    class SelfTypeConstraint < TypeConstraint
      acts_as_struct :scope
    end
    
    class ClassConstraint < Base
      acts_as_struct :class_name, :variance
    end
    
    class GenericClassConstraint < ClassConstraint
      acts_as_struct :subtype_constraints
      def initialize(*args)
        if args.size <= 2
          super(args)
        else
          super(args[0..1])
          @subtype_constraints = args[2..-1]
        end
      end
    end
  end
end
