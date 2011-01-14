module Wool
  module SexpAnalysis
    # This module contains bootstrapping code. This initializes the first classes
    # and modules that build up the meta-model (Class, Module, Object).
    module Bootstrap
      extend SexpAnalysis
      class BootstrappingError < StandardError; end
      def self.bootstrap
        class_class = WoolClass.new('Class', nil)
        module_class = WoolClass.new('Module', nil)
        object_class = WoolClass.new('Object', nil)
        class_scope = ClosedScope.new(nil, class_class)
        module_scope = ClosedScope.new(nil, module_class)
        object_scope = ClosedScope.new(nil, object_class)
        module_class.superclass = object_class
        class_class.superclass = module_class
        main_object = WoolObject.new(object_class, nil, 'main')
        global = ClosedScope.new(nil, main_object,
            {'Object' => object_class, 'Module' => module_class, 'Class' => class_class})
        if Scope.const_defined?("GlobalScope")
          raise BootstrappingError.new('GlobalScope has already been initialized')
        else
          Scope.const_set("GlobalScope", global) 
        end
        class_scope.parent = Scope::GlobalScope
        module_scope.parent = Scope::GlobalScope
        object_scope.parent = Scope::GlobalScope
        object_class.instance_variable_set("@scope", object_scope)
        module_class.instance_variable_set("@scope", module_scope)
        class_class.instance_variable_set("@scope", class_scope)
        # move these to a real ruby file that gets run through the scanner at
        # boot time
        WoolClass.new('Array') { |klass| klass.superclass = object_class }
        WoolClass.new('Proc')  { |klass| klass.superclass = object_class }
      rescue StandardError => err
        new_exception = BootstrappingError.new("Bootstrapping failed: #{err.message}")
        new_exception.set_backtrace(err.backtrace)
        raise new_exception
      end
    
      def self.load_prepackaged_annotations(file)
        parse(File.read(File.join(Wool::ROOT, 'wool', 'standard_library', file)))
      end
    end
  end
end