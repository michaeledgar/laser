module Laser
  module SexpAnalysis
    # This module contains bootstrapping code. This initializes the first classes
    # and modules that build up the meta-model (Class, Module, Object).
    module Bootstrap
      extend SexpAnalysis
      class BootstrappingError < StandardError; end
      def self.bootstrap
        class_class = LaserClass.new(nil, nil, 'Class')
        module_class = LaserClass.new(nil, nil, 'Module')
        object_class = LaserClass.new(nil, nil, 'Object')
        class_scope = ClosedScope.new(nil, class_class)
        module_scope = ClosedScope.new(nil, module_class)
        object_scope = ClosedScope.new(nil, object_class)
        module_class.superclass = object_class
        class_class.superclass = module_class
        main_object = LaserObject.new(object_class, nil, 'main')
        global = ClosedScope.new(nil, main_object,
            {'Object' => Bindings::ConstantBinding.new('Object', object_class),
             'Module' => Bindings::ConstantBinding.new('Module', module_class),
             'Class' => Bindings::ConstantBinding.new('Class', class_class) })
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
        object_class.instance_variable_set("@klass", class_class)
        module_class.instance_variable_set("@klass", class_class)
        class_class.instance_variable_set("@klass", class_class)
        
        true_class = LaserSingletonClass.new(class_class, Scope::GlobalScope, 'TrueClass', 'true')
        false_class = LaserSingletonClass.new(class_class, Scope::GlobalScope, 'FalseClass', 'false')
        nil_class = LaserSingletonClass.new(class_class, Scope::GlobalScope, 'NilClass', 'nil')

        Scope::GlobalScope.add_binding!(
            Bindings::KeywordBinding.new('true', true_class.get_instance))
        Scope::GlobalScope.add_binding!(
            Bindings::KeywordBinding.new('false', false_class.get_instance))
        Scope::GlobalScope.add_binding!(
            Bindings::KeywordBinding.new('nil', nil_class.get_instance))
          
        # Need literal classes or we can't analyze anything
        global.add_binding!(Bindings::ConstantBinding.new(
            'String', LaserClass.new(class_class, Scope::GlobalScope, 'String')))
        global.add_binding!(Bindings::ConstantBinding.new(
            'Regexp', LaserClass.new(class_class, Scope::GlobalScope, 'Regexp')))

      rescue StandardError => err
        new_exception = BootstrappingError.new("Bootstrapping failed: #{err.message}")
        new_exception.set_backtrace(err.backtrace)
        raise new_exception
      end
    
      def self.load_prepackaged_annotations(file)
        parse(File.read(File.join(Laser::ROOT, 'laser', 'standard_library', file)))
      end
    end
  end
end