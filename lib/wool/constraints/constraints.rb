module Wool
  module Constraints
    class Base
    end

    class TypeConstraint < Base
    end

    class SelfTypeConstraint < TypeConstraint
    end
    
    class ClassConstraint < Base
      attr_accessor :class_name, :variance
      def initialize(class_name, variance)
        @class_name = class_name
        @variance = variance
      end
    end
  end
end
