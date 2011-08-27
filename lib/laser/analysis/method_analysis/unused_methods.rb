module Laser
  module Analysis
    module UnusedMethodDetection
      def unused_methods
        each_user_method.reject do |method|
          method.dispatched? || method.builtin || method.special
        end
      end
    end
  end
end
