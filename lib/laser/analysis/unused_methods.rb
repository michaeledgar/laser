module Laser
  module Analysis
    module UnusedMethodDetection
      def self.unused_methods
        methods = []
        classes = Set[]
        Analysis::ProtocolRegistry.class_protocols.each do |key, klass|
          next if Analysis::LaserSingletonClass === klass || classes.include?(klass)
          klass.__all_instance_methods(false).each do |name|
            method = klass.instance_method(name)
            unless method.dispatched? || method.builtin || method.special
              methods << method
            end
          end
          classes << klass
        end
        methods
      end
    end
  end
end