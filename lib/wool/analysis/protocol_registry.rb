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
        self.class_protocols[class_protocol.value.path] = class_protocol
      end

      def self.[](class_name)
        query(:class_path => class_name.gsub(/^::/, ''))
      end

      def self.query(query={})
        if query[:class_path]
          result = self.class_protocols[query[:class_path]]
          result ? [result] : []
        end
      end
    end
    
    module ClassRegistry
      def self.[](class_name)
        if ProtocolRegistry[class_name].any?
        then ProtocolRegistry[class_name].first.value
        else raise ArgumentError.new("No class found with the path #{class_name}.")
        end
      end
      
      def self.bootstrap
        class_class = WoolClass.new('Class', nil)
        module_class = WoolClass.new('Module', nil)
        object_class = WoolClass.new('Object', nil)
        class_scope = Scope.new(nil, class_class)
        module_scope = Scope.new(nil, module_class)
        object_scope = Scope.new(nil, object_class)
        module_class.superclass = object_class
        class_class.superclass = module_class
        main_object = WoolObject.new(object_class, nil, 'main')
        global = Scope.new(nil, main_object,
            {'Object' => object_class, 'Module' => module_class, 'Class' => class_class})
        unless SexpAnalysis.const_defined?("GlobalScope")
          Scope.const_set("GlobalScope", global) 
        end
        class_scope.parent = Scope::GlobalScope
        module_scope.parent = Scope::GlobalScope
        object_scope.parent = Scope::GlobalScope
        object_class.instance_variable_set("@scope", main_object)
        object_class.instance_variable_set("@scope", object_scope)
        module_class.instance_variable_set("@scope", module_scope)
        class_class.instance_variable_set("@scope", class_scope)
      end
    end
  end
end