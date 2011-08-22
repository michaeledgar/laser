module Laser
  module Analysis
    module OverrideSafetyInfo
      def self.warn_on_any_override?(method)
        do_not_override.include?(method)
      end

      # Returns the warning message when +method+ is overridden. Since
      # we may actually be overriding an alias, we need to provide the
      # name of the override, and substitute it into the message.
      def self.warning_message(method, overridden_name)
        do_not_override[method] % overridden_name
      end

      def self.do_not_override
        return @do_not_override if @do_not_override
        result = Hash[
          ClassRegistry['Module'].instance_method(:public),
          'Overriding Module#%s breaks its zero-argument lexically-scoped behavior.',
          ClassRegistry['Module'].instance_method(:private),
          'Overriding Module#%s breaks its zero-argument lexically-scoped behavior.',
          ClassRegistry['Module'].instance_method(:protected),
          'Overriding Module#%s breaks its zero-argument lexically-scoped behavior.',
          ClassRegistry['Module'].instance_method(:module_function),
          'Overriding Module#%s breaks its zero-argument lexically-scoped behavior.',
          ClassRegistry['Kernel'].instance_method(:block_given?),
          'Overriding Kernel#%s irreparably breaks the method.',
          ClassRegistry['Kernel'].instance_method(:binding),
          'Overriding Kernel#%s irreparably breaks the method.',
          ClassRegistry['Kernel'].instance_method(:callcc),
          'Overriding Kernel#%s may give highly surprising results.',
          ClassRegistry['Kernel'].instance_method(:caller),
          'Overriding Kernel#%s may work, but must be done very carefully.',
          ClassRegistry['Kernel'].instance_method(:__method__),
          'Overriding Kernel#%s irreparably breaks the method.',
          ClassRegistry['Kernel'].instance_method(:local_variables),
          'Overriding Kernel#%s irreparably breaks the method.',
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