module Laser
  module SexpAnalysis
    # This module contains bootstrapping code. This initializes the first classes
    # and modules that build up the meta-model (Class, Module, Object).
    module Bootstrap
      extend SexpAnalysis
      VISIBILITY_STACK_NAME = '$#visibility_stack'
      VISIBILITY_STACK = Bindings::GlobalVariableBinding.new(VISIBILITY_STACK_NAME, [:private])
      EXCEPTION_STACK_NAME = '$#exception_stack'
      EXCEPTION_STACK = Bindings::GlobalVariableBinding.new(EXCEPTION_STACK_NAME, [])
      class BootstrappingError < StandardError; end
      def self.bootstrap
        object_class = LaserClass.new(nil, nil, 'Object')
        ProtocolRegistry.add_class(object_class)
        class_class = LaserClass.new(nil, nil, 'Class')
        ProtocolRegistry.add_class(class_class)
        module_class = LaserClass.new(nil, nil, 'Module')
        ProtocolRegistry.add_class(module_class)
        basic_object_class = LaserClass.new(nil, nil, 'BasicObject')
        ProtocolRegistry.add_class(basic_object_class)
        class_scope = ClosedScope.new(nil, class_class)
        module_scope = ClosedScope.new(nil, module_class)
        object_scope = ClosedScope.new(nil, object_class)
        basic_object_scope = ClosedScope.new(nil, basic_object_class)
        object_class.superclass = basic_object_class
        module_class.superclass = object_class
        class_class.superclass = module_class
        main_object = LaserObject.new(object_class, nil, 'main')
        global = ClosedScope.new(nil, main_object,
            {'Object' => Bindings::ConstantBinding.new('Object', object_class),
             'Module' => Bindings::ConstantBinding.new('Module', module_class),
             'Class' => Bindings::ConstantBinding.new('Class', class_class),
             'BasicObject' => Bindings::ConstantBinding.new('BasicObject', basic_object_class) },
            {'self' => main_object})
        if Scope.const_defined?("GlobalScope")
          raise BootstrappingError.new('GlobalScope has already been initialized')
        else
          Scope.const_set("GlobalScope", global) 
        end
        class_scope.parent = Scope::GlobalScope
        module_scope.parent = Scope::GlobalScope
        object_scope.parent = Scope::GlobalScope
        basic_object_scope.parent = Scope::GlobalScope
        basic_object_class.instance_variable_set("@scope", basic_object_scope)
        object_class.instance_variable_set("@scope", object_scope)
        module_class.instance_variable_set("@scope", module_scope)
        class_class.instance_variable_set("@scope", class_scope)
        object_class.const_set('BasicObject', basic_object_class)
        object_class.const_set('Object', object_class)
        object_class.const_set('Module', module_class)
        object_class.const_set('Class', class_class)
        basic_object_class.instance_variable_set("@klass", class_class)
        object_class.instance_variable_set("@klass", class_class)
        module_class.instance_variable_set("@klass", class_class)
        class_class.instance_variable_set("@klass", class_class)
        bootstrap_literals
      rescue StandardError => err
        new_exception = BootstrappingError.new("Bootstrapping failed: #{err.message}")
        new_exception.set_backtrace(err.backtrace)
        raise new_exception
      end
      
      def self.bootstrap_magic
        class_class = ClassRegistry['Class']
        magic_class = LaserClass.new(
            class_class, Scope::GlobalScope, 'Laser#Magic')
        ClassRegistry['Object'].const_set('Laser#Magic', magic_class)
        stub_method(magic_class.singleton_class, 'current_block', special: true)
        stub_method(magic_class.singleton_class, 'current_arity', special: true)
        stub_method(magic_class.singleton_class, 'current_argument', special: true)
        stub_method(magic_class.singleton_class, 'current_argument_range', special: true)
        stub_method(magic_class.singleton_class, 'current_exception', special: true)
        stub_method(magic_class.singleton_class, 'push_exception', special: true, mutation: true)
        stub_method(magic_class.singleton_class, 'pop_exception', special: true, mutation: true)
        stub_method(magic_class.singleton_class, 'current_self', special: true)
        stub_method(magic_class.singleton_class, 'get_global', special: true)
        stub_method(magic_class.singleton_class, 'set_global', special: true, mutation: true)
      end
      
      # Before we analyze any code, we need to create classes for all the
      # literals that are in Ruby. Otherwise, when we see those literals,
      # if we haven't yet created the class they are an instance of, shit
      # will blow up.
      def self.bootstrap_literals
        global = Scope::GlobalScope
        class_class = ClassRegistry['Class']
        object_class = ClassRegistry['Object']
        true_class = LaserSingletonClass.new(class_class, ClosedScope.new(Scope::GlobalScope, nil), 'TrueClass', 'true')
        false_class = LaserSingletonClass.new(class_class, ClosedScope.new(Scope::GlobalScope, nil), 'FalseClass', 'false')
        nil_class = LaserSingletonClass.new(class_class, ClosedScope.new(Scope::GlobalScope, nil), 'NilClass', 'nil')
        object_class.const_set('TrueClass', true_class)
        object_class.const_set('FalseClass', true_class)
        object_class.const_set('NilClass', true_class)

        global.add_binding!(
            Bindings::KeywordBinding.new('true', true_class.get_instance))
        global.add_binding!(
            Bindings::KeywordBinding.new('false', false_class.get_instance))
        global.add_binding!(
            Bindings::KeywordBinding.new('nil', nil_class.get_instance))

        kernel_module = stub_toplevel_module('Kernel')
        object_class.include(kernel_module)
        stub_toplevel_class 'Proc'
        stub_toplevel_class 'Array'
        stub_toplevel_class 'String'
        stub_toplevel_class 'Hash'
        stub_toplevel_class 'Regexp'
        stub_toplevel_class 'Range'
        stub_toplevel_class 'Symbol'
        stub_toplevel_class 'Numeric'
        stub_toplevel_class 'Float', 'Numeric'
        stub_toplevel_class 'Integer', 'Numeric'
        stub_toplevel_class 'Fixnum', 'Integer'
        stub_toplevel_class 'Bignum', 'Integer'
        stub_toplevel_class 'Exception'
        stub_toplevel_class 'StandardError', 'Exception'
        stub_toplevel_class 'TypeError', 'StandardError'
        # My specific tweaks
        stub_toplevel_class 'LaserTypeErrorWrapper', 'TypeError'
        stub_toplevel_class 'LaserReopenedClassAsModuleError', 'LaserTypeErrorWrapper'
        stub_toplevel_class 'LaserReopenedModuleAsClassError', 'LaserTypeErrorWrapper'
        stub_toplevel_class 'LaserSuperclassMismatchError', 'LaserTypeErrorWrapper'
        
        global.add_binding!(Bindings::GlobalVariableBinding.new('$:',
            ['.', File.expand_path(File.join(File.dirname(__FILE__), '..', 'standard_library'))]))
        global.add_binding!(Bindings::GlobalVariableBinding.new('$"', []))
        global.add_binding!(VISIBILITY_STACK)
        stub_core_methods
      end
      
      def self.stub_core_methods
        class_class = ClassRegistry['Class']
        module_class = ClassRegistry['Module']
        kernel_module = ClassRegistry['Kernel']
        array_class = ClassRegistry['Array']
        hash_class = ClassRegistry['Hash']
        def hash_class.[](*args)
          ::Hash[*args]
        end
        def array_class.[](*args)
          ::Array[*args]
        end
        def array_class.new(*args)
          ::Array.new(*args)
        end
        string_class = ClassRegistry['String']
        stub_method(class_class.singleton_class, 'new', builtin: true, pure: true)
        stub_method(class_class, 'superclass', builtin: true, pure: true, raises: Frequency::NEVER)
        stub_method(class_class, 'new')
        stub_method(module_class, 'define_method', builtin: true, pure: true, mutation: true)
        stub_method(module_class, 'define_method_with_annotations', builtin: true, pure: true, mutation: true)
        stub_method(module_class.singleton_class, 'new', builtin: true, pure: true)
        stub_method(module_class, 'const_defined?', builtin: true, raises: Frequency::NEVER)
        stub_method(module_class, 'const_set', builtin: true, mutation: true)
        stub_method(module_class, 'const_get', builtin: true)
        stub_method(module_class, '===', builtin: true, pure: true, raises: Frequency::NEVER)
        stub_method(kernel_module, 'eql?', builtin: true, pure: true,
            raises: Frequency::NEVER)
        stub_method(kernel_module, 'equal?', builtin: true, pure: true,
            raises: Frequency::NEVER)
        stub_method(kernel_module, 'singleton_class', builtin: true, pure: true,
            raises: Frequency::NEVER)
        stub_method(array_class, 'push', builtin: true, mutation: true, raises: Frequency::NEVER)
        stub_method(array_class, 'pop', builtin: true, mutation: true, raises: Frequency::NEVER)
        stub_method(array_class.singleton_class, '[]', builtin: true, pure: true, raises: Frequency::NEVER)
        stub_method(hash_class.singleton_class, '[]', builtin: true, pure: true)
        stub_method(string_class, '+', builtin: true, pure: true)
      end
      
      def self.stub_method(klass, name, opts={})
        method = LaserMethod.new(name)
        opts.each { |k, v| method.send("#{k}=", v) }
        klass.add_instance_method!(method)
      end
      
      def self.stub_toplevel_class(name, superclass_name='Object')
        klass = LaserClass.new(ClassRegistry['Class'], ClosedScope.new(Scope::GlobalScope, nil), name) do |klass|
          klass.superclass = ClassRegistry[superclass_name]
        end
        ClassRegistry['Object'].const_set(name, klass)
        klass
      end

      def self.stub_toplevel_module(name)
        # i say "module" like "mojule" anyway, so i'll use that as the misspelling
        mojule = LaserModule.new
        ClassRegistry['Object'].const_set(name, mojule)
        mojule
      end
    end
  end
end