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
             'Class' => Bindings::ConstantBinding.new('Class', class_class) },
            {'self' => main_object})
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
        bootstrap_literals
      rescue StandardError => err
        new_exception = BootstrappingError.new("Bootstrapping failed: #{err.message}")
        new_exception.set_backtrace(err.backtrace)
        raise new_exception
      end
      
      # Before we analyze any code, we need to create classes for all the
      # literals that are in Ruby. Otherwise, when we see those literals,
      # if we haven't yet created the class they are an instance of, shit
      # will blow up.
      def self.bootstrap_literals
        global = Scope::GlobalScope
        class_class = ClassRegistry['Class']
        true_class = LaserSingletonClass.new(class_class, Scope::GlobalScope, 'TrueClass', 'true')
        false_class = LaserSingletonClass.new(class_class, Scope::GlobalScope, 'FalseClass', 'false')
        nil_class = LaserSingletonClass.new(class_class, Scope::GlobalScope, 'NilClass', 'nil')

        global.add_binding!(
            Bindings::KeywordBinding.new('true', true_class.get_instance))
        global.add_binding!(
            Bindings::KeywordBinding.new('false', false_class.get_instance))
        global.add_binding!(
            Bindings::KeywordBinding.new('nil', nil_class.get_instance))

        superclass_assignment = proc { |klass| klass.superclass = ClassRegistry['Object'] }
        global.add_binding!(Bindings::ConstantBinding.new(
            'Array', LaserClass.new(class_class, ClosedScope.new(Scope::GlobalScope, nil), 'Array', &superclass_assignment)))
        global.add_binding!(
            Bindings::GlobalVariableBinding.new('$:',
              RealObjectProxy.new(ClassRegistry['Array'], global, '$:',
                [File.expand_path(File.join(File.dirname(__FILE__), '..', 'standard_library'))])))
        global.add_binding!(
            Bindings::GlobalVariableBinding.new('$"',
              RealObjectProxy.new(ClassRegistry['Array'], global, '$"', [])))
      end
    end
  end
end