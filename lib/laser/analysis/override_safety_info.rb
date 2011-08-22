module Laser
  module Analysis
    module OverrideSafetyInfo
      def self.warn_on_any_override?(method)
        do_not_override.include?(method)
      end

      def self.warning_message(method)
        do_not_override[method]
      end

      def self.do_not_override
        return @do_not_override if @do_not_override
        result = Hash[
          ClassRegistry['Module'].instance_method(:public),
          'Overriding Module#public breaks its zero-argument lexically-scoped behavior.',
          ClassRegistry['Module'].instance_method(:private),
          'Overriding Module#private breaks its zero-argument lexically-scoped behavior.',
          ClassRegistry['Module'].instance_method(:protected),
          'Overriding Module#protected breaks its zero-argument lexically-scoped behavior.',
          ClassRegistry['Module'].instance_method(:module_function),
          'Overriding Module#module_function breaks its zero-argument lexically-scoped behavior.'
        ]
        unless result[nil]  # if all keys existed
          @do_not_override = result
        end
        result
      end
      class << self
        private :do_not_override
        @do_not_override = nil
      end
    end
  end
end