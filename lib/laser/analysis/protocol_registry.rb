module Laser
  module Analysis
    # The ProtocolRegistry module handles negotiating instantiated protocols at
    # compile-time, such as the automatically-generated protocols created by a
    # class creation (as each class has a corresponding protocol, though some
    # distinct classes may have equivalent protocols).
    module ProtocolRegistry
      extend ModuleExtensions
      cattr_accessor_with_default :class_protocols, {}

      def self.add_class(klass)
        self.class_protocols[klass.path] = klass
      end

      def self.[](class_name)
        result = self.class_protocols[class_name.gsub(/^::/, '')]
        result ? [result] : []
      end
    end
    
    module ClassRegistry
      def self.[](class_name)
        if ProtocolRegistry[class_name].any?
        then ProtocolRegistry[class_name].first
        else raise ArgumentError.new("No class found with the path #{class_name}.")
        end
      end
    end
  end
end
