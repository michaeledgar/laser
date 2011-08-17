module Laser
  module Analysis
    UNDEFINED = PlaceholderObject.new('UNDEFINED')
    VARYING = PlaceholderObject.new('VARYING')

    # This module contains bootstrapping code. This initializes the first classes
    # and modules that build up the meta-model (Class, Module, Object).
    module Bootstrap
      extend Analysis
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
          global.lexical_target = object_class.binding
          Scope.const_set("GlobalScope", global) 
        end
        class_scope.parent = Scope::GlobalScope
        module_scope.parent = Scope::GlobalScope
        object_scope.parent = Scope::GlobalScope
        basic_object_scope.parent = Scope::GlobalScope
        basic_object_class.instance_eval { @scope = basic_object_scope }
        object_class.instance_eval { @scope = object_scope }
        module_class.instance_eval { @scope = module_scope }
        class_class.instance_eval { @scope = class_scope }
        object_class.const_set('BasicObject', basic_object_class)
        object_class.const_set('Object', object_class)
        object_class.const_set('Module', module_class)
        object_class.const_set('Class', class_class)
        basic_object_class.instance_eval { @klass = class_class }
        object_class.instance_eval { @klass = class_class }
        module_class.instance_eval { @klass = class_class }
        class_class.instance_eval { @klass = class_class }
        
        # Bootstrap order: core classes, then methods
        bootstrap_literals
        stub_core_methods
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
        stub_method(magic_class.singleton_class, 'current_block', special: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(magic_class.singleton_class, 'current_arity', special: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(magic_class.singleton_class, 'current_argument', special: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(magic_class.singleton_class, 'current_argument_range', special: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(magic_class.singleton_class, 'current_exception', special: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(magic_class.singleton_class, 'get_just_raised_exception', special: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(magic_class.singleton_class, 'push_exception', special: true, mutation: true, annotated_return: Types::EMPTY, annotated_raise_frequency: Frequency::NEVER)
        stub_method(magic_class.singleton_class, 'pop_exception', special: true, mutation: true, annotated_return: Types::EMPTY, annotated_raise_frequency: Frequency::NEVER)
        stub_method(magic_class.singleton_class, 'current_self', special: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(magic_class.singleton_class, 'get_global', special: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(magic_class.singleton_class, 'set_global', special: true, mutation: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(magic_class.singleton_class, 'responds?', special: true, annotated_raise_frequency: Frequency::NEVER)
        
        ClassRegistry['Module'].instance_method(:const_defined?).annotated_return = Types::BOOLEAN
        ClassRegistry['Module'].instance_method(:===).annotated_return = Types::BOOLEAN
        ClassRegistry['Kernel'].instance_method(:eql?).annotated_return = Types::BOOLEAN
        ClassRegistry['Kernel'].instance_method(:equal?).annotated_return = Types::BOOLEAN
        ClassRegistry['Kernel'].instance_method(:raise).annotated_return = Types::EMPTY
        ClassRegistry['Proc'].instance_method(:lexical_self=).annotated_return = Types::EMPTY
        
        stub_global_vars
      end
      
      # Before we analyze any code, we need to create classes for all the
      # literals that are in Ruby. Otherwise, when we see those literals,
      # if we haven't yet created the class they are an instance of, shit
      # will blow up.
      def self.bootstrap_literals
        global = Scope::GlobalScope
        class_class = ClassRegistry['Class']
        object_class = ClassRegistry['Object']
        true_class = LaserSingletonClass.new(class_class, ClosedScope.new(Scope::GlobalScope, nil), 'TrueClass', 'true') do |klass|
          klass.superclass = object_class
        end
        false_class = LaserSingletonClass.new(class_class, ClosedScope.new(Scope::GlobalScope, nil), 'FalseClass', 'false') do |klass|
          klass.superclass = object_class
        end
        nil_class = LaserSingletonClass.new(class_class, ClosedScope.new(Scope::GlobalScope, nil), 'NilClass', 'nil') do |klass|
          klass.superclass = object_class
        end
        object_class.const_set('TrueClass', true_class)
        object_class.const_set('FalseClass', false_class)
        object_class.const_set('NilClass', nil_class)

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
        
        stub_toplevel_class 'IO'  # TODO(adgar): includes File::Constants and Enumerable...
      end
      
      def self.stub_core_methods
        class_class = ClassRegistry['Class']
        module_class = ClassRegistry['Module']
        kernel_module = ClassRegistry['Kernel']
        array_class = ClassRegistry['Array']
        hash_class = ClassRegistry['Hash']
        range_class = ClassRegistry['Range']
        regexp_class = ClassRegistry['Regexp']
        proc_class = ClassRegistry['Proc']
        def hash_class.[](*args)
          ::Hash[*args]
        end
        def array_class.[](*args)
          ::Array[*args]
        end
        def array_class.new(*args)
          ::Array.new(*args)
        end
        def range_class.new(*args)
          ::Range.new(*args)
        end
        def regexp_class.new(*args)
          ::Regexp.new(*args)
        end
        string_class = ClassRegistry['String']
        stub_method(class_class.singleton_class, 'new', builtin: true, pure: true)
        stub_method(class_class, 'superclass', builtin: true, pure: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(class_class, 'new')
        allocate_method = stub_method(class_class, 'allocate', special: true, pure: true, annotated_raise_frequency: Frequency::NEVER)
        def allocate_method.return_type_for_types(self_type, arg_types, block_type)
          unless arg_types.empty? && block_type == Types::NILCLASS
            raise TypeError.new("Class#allocate takes no arguments and no block")
          end
          Types::ClassObjectType.new(self_type.possible_classes.first.get_instance)
        end
        stub_method(module_class, 'define_method', builtin: true, pure: true, mutation: true)
        stub_method(module_class, 'define_method_with_annotations', builtin: true, pure: true, mutation: true)
        stub_method(module_class.singleton_class, 'new', builtin: true, pure: true)
        stub_method(module_class, 'const_defined?', builtin: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(module_class, 'const_set', builtin: true, mutation: true)
        stub_method(module_class, 'const_get', builtin: true)
        stub_method(module_class, '===', builtin: true, pure: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(kernel_module, 'eql?', builtin: true, pure: true,
            annotated_raise_frequency: Frequency::NEVER)
        stub_method(kernel_module, 'equal?', builtin: true, pure: true,
            annotated_raise_frequency: Frequency::NEVER)
        stub_method(kernel_module, 'singleton_class', builtin: true, pure: true,
            annotated_raise_frequency: Frequency::NEVER)
        
        send_method = stub_custom_method(kernel_module, SpecialMethods::SendMethod, 'send', :any, special: true)
        send_method.arity = Arity.new(1..Float::INFINITY)
        send_method = stub_custom_method(kernel_module, SpecialMethods::SendMethod, 'public_send', :public, special: true)
        send_method.arity = Arity.new(1..Float::INFINITY)
        
        raise_method = stub_method(kernel_module, 'raise', builtin: true, pure: true,
            annotated_raise_frequency: Frequency::ALWAYS)
        def raise_method.raise_type_for_types(self_type, arg_types, block_type)
          if arg_types.size == 0
            ClassRegistry['RuntimeError'].as_type
          else
            Types::UnionType.new(arg_types[0].possible_classes.map do |arg_class|
              if arg_class <= ClassRegistry['String']
                ClassRegistry['RuntimeError'].as_type
              elsif LaserSingletonClass === arg_class && arg_class < ClassRegistry['Class']
                arg_class.get_instance.as_type
              elsif arg_class <= ClassRegistry['Exception']
                arg_class.as_type
              elsif arg_class.instance_method_defined?('exception')
                arg_class.instance_method(:exception).return_type_for_types(arg_class.as_type)
              end
            end)
          end
        end
        stub_method(array_class, 'push', builtin: true, mutation: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(array_class, 'pop', builtin: true, mutation: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(array_class.singleton_class, '[]', builtin: true, pure: true, annotated_raise_frequency: Frequency::NEVER)
        stub_method(hash_class.singleton_class, '[]', builtin: true, pure: true)
        stub_method(string_class, '+', builtin: true, pure: true)
        stub_method(proc_class, 'lexical_self=', builtin: true, mutation: true, annotated_raise_frequency: Frequency::NEVER)
      end
      
      def self.stub_global_vars
        Scope::GlobalScope.add_binding!(Bindings::GlobalVariableBinding.new('$:',
            ['.', File.expand_path(File.join(Laser::ROOT, 'laser', 'standard_library'))]))
        Scope::GlobalScope.add_binding!(Bindings::GlobalVariableBinding.new('$"', []))
        Scope::GlobalScope.add_binding!(VISIBILITY_STACK)

        stub_global_type('$0', Types::STRING)
        stub_global_type('$*', Types::ARRAY)
        stub_global_type('$$', Types::FIXNUM)  # I hope pids fit in a fixnum
        stub_global_type('$.', Types::FIXNUM)
        stub_global_type('$&', Types.optional(Types::STRING))
        stub_global_type('$`', Types.optional(Types::STRING))
        stub_global_type("$'", Types.optional(Types::STRING))
      end
      
      def self.load_standard_library
        LaserMethod.default_dispatched = true
          %w(class_definitions.rb).map do |file|
            path = File.join(Laser::ROOT, 'laser', 'standard_library', file)
            [path, File.read(path)]
          end.tap do |tuples|
          begin
            trees = Annotations.annotate_inputs(tuples, optimize: false)
            trees.each do |filename, tree|
              if tree.all_errors != []
                $stderr.puts "Default file #{filename} had these errors:"
                PP.pp(tree.all_errors, $stderr)
                exit 1
              end
            end
          rescue StandardError => err
            puts "Loading class definitions failed:"
            p err.message
            pp err
            pp err.backtrace
          end
        end
        # All methods from here on out will need to be used, or a warning will be issued.
        LaserMethod.default_dispatched = false
      end

      def self.stub_method(klass, name, opts={})
        stub_custom_method(klass, LaserMethod, name, nil, opts)
      end
      
      def self.stub_custom_method(klass, custom_class, *init_args, opts)
        method = custom_class.new(*init_args)
        opts.each { |k, v| method.send("#{k}=", v) }
        klass.add_instance_method!(method)
        method
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
      
      def self.stub_global_type(name, type)
        Scope::GlobalScope.lookup(name).inferred_type = type
      end
    end
  end
end
