module Wool
  module SexpAnalysis
    # The ProtocolRegistry module handles negotiating instantiated protocols at
    # compile-time, such as the automatically-generated protocols created by a
    # class creation (as each class has a corresponding protocol, though some
    # distinct classes may have equivalent protocols).
    module ProtocolRegistry
      extend ModuleExtensions
      cattr_accessor_with_default :protocols, []
      cattr_accessor_with_default :class_protocols, {}

      def self.add_protocol(proto)
        self.protocols << proto
      end
      
      def self.add_class_protocol(class_protocol)
        add_protocol class_protocol
        self.class_protocols[class_protocol.class_used.path] = class_protocol
      end

      def self.[](class_name)
        query(:class_path => class_name.gsub(/^::/, ''))
      end

      def self.query(query={})
        if query[:class_path]
          [self.class_protocols[query[:class_path]]]
        end
      end
    end
    
    module ClassRegistry
      def self.[](class_name)
        if ProtocolRegistry[class_name].any?
        then ProtocolRegistry[class_name].first.class_used
        else raise ArgumentError.new("No class found with the path #{class_name}.")
        end
      end
      
      def self.initialize_global_scope
        class_class = SexpAnalysis::WoolClass.new('Class', nil)
        module_class = SexpAnalysis::WoolClass.new('Module', nil)
        object_class = SexpAnalysis::WoolClass.new('Object', nil)
        module_class.superclass = object_class
        class_class.superclass = module_class
        global = SexpAnalysis::Scope.new(nil, object_class.object, {'Object' => object_class})
        SexpAnalysis::Scope.const_set("GlobalScope", global) unless SexpAnalysis.const_defined?("GlobalScope")
        object_class.instance_variable_set("@scope", SexpAnalysis::Scope::GlobalScope)
        module_class.instance_variable_set("@scope", SexpAnalysis::Scope::GlobalScope)
        class_class.instance_variable_set("@scope", SexpAnalysis::Scope::GlobalScope)
      end
    end
  end
end