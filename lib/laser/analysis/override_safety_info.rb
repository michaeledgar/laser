module Laser
  module Analysis
    module OverrideSafetyInfo
      def self.warn_on_any_override?(method)
        do_not_override.include?(method)
      end

      def self.needs_super_on_override?(method)
        super_when_override.include?(method)
      end

      # Returns the warning message when +method+ is overridden. Since
      # we may actually be overriding an alias, we need to provide the
      # name of the override, and substitute it into the message.
      def self.warning_message(method, overridden_name)
        (do_not_override[method] || super_when_override[method]) % overridden_name
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

      ALWAYS_CALL_SUPER_KERNEL = 'Always call super when overriding Kernel#%s.'
      ALWAYS_CALL_SUPER_MODULE = 'Always call super when overriding Module#%s.'
      KERNEL_SUPER_NEEDED = %w(throw catch raise loop proc lambda throw abort
        autoload method methods exit exit! sleep puts p fork exec warn test trap)
      MODULE_SUPER_NEEDED = %w(attr attr_reader attr_writer attr_accessor include
        extend)
      def self.super_when_override
        return @super_when_override if @super_when_override
        kernel = ClassRegistry['Kernel']
        mod = ClassRegistry['Module']
        kernel_members = KERNEL_SUPER_NEEDED.map do |method|
          [kernel.instance_method(method), ALWAYS_CALL_SUPER_KERNEL]
        end
        module_members = MODULE_SUPER_NEEDED.map do |method|
          [mod.instance_method(method), ALWAYS_CALL_SUPER_MODULE]
        end
        result = Hash[*(kernel_members + module_members).flatten]
        unless result[nil]  # if all keys existed
          @super_when_override = result
        end
        result
      end

      class << self
        private :do_not_override, :super_when_override
        @do_not_override = nil
        @super_when_override = nil
      end
    end
  end
end
