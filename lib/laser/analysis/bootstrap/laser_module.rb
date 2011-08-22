module Laser
  module Analysis
    # Laser representation of a module. Named LaserModule to avoid naming
    # conflicts. It has lists of methods, instance variables, and so on.
    class LaserModule < LaserObject
      attr_reader :binding, :superclass
      attr_accessor :path
      cattr_accessor_with_default :all_modules, []
      
      def initialize(klass = ClassRegistry['Module'], scope = Scope::GlobalScope,
                     full_path=(@name_set = :no; "#{klass.path}:Anonymous:#{object_id.to_s(16)}"))
        super(klass, scope, full_path.split('::').last)
        full_path = submodule_path(full_path) if scope && scope.parent
        validate_module_path!(full_path) unless LaserSingletonClass === self

        @name_set = :yes unless @name_set == :no
        @path = full_path
        @instance_methods = {}
        @visibility_table = {}
        @constant_table = {}
        @scope = scope
        @ivar_types = {}
        @superclass ||= nil
        initialize_protocol
        @binding = Bindings::ConstantBinding.new(name, self)
        initialize_scope
        yield self if block_given?
        LaserModule.all_modules << self
      end

      def <=>(other)
        if self == other
          return 0
        elsif ancestors.include?(other)
          return -1
        elsif other.ancestors.include?(self)
          return 1
        else
          return nil
        end
      end
      
      # including Comparable is having issues due to override of include. Do it
      # ourselves.
      %w(< <= >= >).each do |op|
        class_eval %Q{
          def #{op}(other)
            cmp = self <=> other
            cmp && cmp #{op} 0
          end
        }
      end

      def as_type
        Types::ClassObjectType.new(self)
      end

      def name_set?
        @name_set == :yes
      end
      
      def set_name(new_path)
        @path = new_path
        ProtocolRegistry.add_class(self)
        @name_set = :yes
      end

      # Returns the canonical path for a (soon-to-be-created) submodule of the given
      # scope. This is computed before creating the module.
      def submodule_path(new_mod_name)
        scope = self.scope.parent
        new_mod_full_path = scope.parent.nil? ? '' : scope.path
        new_mod_full_path += '::' unless new_mod_full_path.empty?
        new_mod_full_path += new_mod_name
      end

      def validate_module_path!(path)
        path.split('::').each do |component|
          if !component.empty? && component[0,1] !~ /[A-Z]/
            raise ArgumentError.new("Path component #{component} in #{path}" +
                                    ' does not start with a capital letter, A-Z.')
          end
        end
      end
      
      def class_name
        'Module'
      end

      # If this is a new, custom module, we can update the constant
      # table and perform module initialization.
      def initialize_scope
        if @scope && !(@scope.parent.nil?)
          @scope.parent.constants[name] = self.binding if @scope.parent
          @scope.locals['self'] = Bindings::LocalVariableBinding.new('self', self)
        end
      end
      
      # Initializes the protocol for this LaserClass.
      def initialize_protocol
        if ProtocolRegistry[path].any? && !TESTS_ACTIVATED
          $stderr.puts "Warning: creating new instance of #{class_name} #{path}"
        else
          ProtocolRegistry.add_class(self)
        end
      end
      
      def name
        self.path.split('::').last
      end
      
      def add_instance_method!(method)
        @instance_methods[method.name.to_sym] = method
        @visibility_table[method.name.to_sym] = :public
        method.owner = self
      end

      def instance_method(name)
        lookup = name.to_sym
        if @instance_methods.has_key?(lookup)
        then @instance_methods[lookup]
        else @superclass && @superclass.instance_method(lookup)
        end
      end
      
      def method_defined?(name)
        instance_method(name) && visibility_for(name) != :private
      end

      def public_instance_method(name)
        result = instance_method(name)
        visibility_for(name) == :public ? result : nil
      end

      def __all_instance_methods(include_super = true)
        mine = @instance_methods.keys
        if include_super && @superclass
        then @superclass.instance_methods | mine
        else mine
        end
      end

      def __instance_methods_with_privacy(include_super, *allowed)
        methods = __all_instance_methods(include_super)
        table = visibility_table
        methods.select { |name| allowed.include?(table[name.to_sym]) }
      end

      def instance_methods(include_super = true)
        __instance_methods_with_privacy(include_super, :public, :protected)
      end

      def public_instance_methods(include_super = true)
        __instance_methods_with_privacy(include_super, :public)
      end
      
      def protected_instance_methods(include_super = true)
        __instance_methods_with_privacy(include_super, :protected)
      end
      
      def protected_method_defined?(name)
        !!__instance_methods_with_privacy(include_super, :protected)
      end
      
      def private_instance_methods(include_super = true)
        __instance_methods_with_privacy(include_super, :private)
      end

      def ivar_type(name)
        @ivar_types[name] || (@superclass && @superclass.ivar_type(name)) || Types::NILCLASS
      end
      
      def set_ivar_type(name, type)
        @ivar_types[name] = type
      end
      
      def instance_variable(name)
        @instance_variables[name] || (@superclass && @superclass.instance_variable(name))
      end
      
      def instance_variables
        if @superclass.nil?
        then @instance_variables
        else @instance_variables.merge(@superclass.instance_variables)
        end
      end
      
      def add_instance_variable!(binding)
        @instance_variables[binding.name] = binding
      end
      
      def visibility_for(method)
        lookup = method.to_sym
        return @visibility_table[lookup] ||
          (@superclass && @superclass.visibility_for(lookup))
      end
      
      def visibility_table
        if @superclass
        then @superclass.visibility_table.merge(@visibility_table)
        else @visibility_table
        end
      end
      
      def set_visibility!(method, visibility)
        @visibility_table[method] = visibility
      end
      
      def superclass=(new_superclass)
        @superclass = new_superclass
      end

      def parent
        @superclass
      end

      # The set of all superclasses (including the class itself)
      def ancestors
        if @superclass.nil?
        then [self]
        else [self] + @superclass.ancestors
        end
      end
      
      def subset
        [self]
      end
      
      def classes_including
        @classes_including ||= []
      end
      
      def included_modules
        ancestors.select { |mod| LaserModuleCopy === mod }
      end
      
      # Directly translated from MRI's C implementation in class.c:650
      def include_module(mod)
        if mod.klass == ClassRegistry['Class']
          raise ArgumentError.new("Tried to include #{mod.name}, which should "+
                                  " be a Module or Module subclass, not a " +
                                  "#{mod.klass.name}.")
        end
        original_mod = mod
        any_changes = false
        current = self
        while mod
          superclass_seen = false
          should_change = true
          if mod == self
            raise ArgumentError.new("Cyclic module inclusion: #{mod} mixed into #{self}")
          end
          ancestors.each do |parent|
            case parent
            when LaserModuleCopy
              if parent == mod
                current = parent unless superclass_seen
                should_change = false
                break
              end
            when LaserClass
              superclass_seen = true
            end
          end
          if should_change
            new_super = (current.superclass = LaserModuleCopy.new(mod, current.ancestors[1]))
            mod.classes_including << current
            current = new_super
            any_changes = true
          end
          mod = mod.superclass
        end
        unless any_changes
          raise DoubleIncludeError.new("Included #{original_mod.path} into #{self.path}"+
                                        " but it was already included.", nil)
        end
      end
      
      def inspect
        "#<LaserModule: #{path}>"
      end
      
      # simulation methods
      def ===(other)
        klass = (LaserObject === other ? other.klass : ClassRegistry[other.class.name])
        klass.ancestors.include?(self)
      end
      
      def const_set(string, value)
        @constant_table[string] = value
        if LaserModule === value && !value.name_set?
          if self == ClassRegistry['Object']
            value.set_name(string)
          else
            value.set_name("#{@path}::#{string}")
          end
        end
      end
      
      def const_get(constant, inherit=true)
        if inherit && superclass
          @constant_table[constant] || superclass.const_get(constant, true)
        elsif LaserClass === self
          @constant_table[constant] or raise ArgumentError.new("Class #{@path} has no constant #{constant}")
        else
          (@constant_table[constant] || ClassRegistry['Object'].const_get(constant, false)) or
              raise ArgumentError.new("Class #{@path} has no constant #{constant}")
        end
      end
      
      # Fuck you, that's why
      def const_defined?(constant, inherit=true)
        !!const_get(constant, inherit)
      rescue
        false
      end
      
      def remove_const(sym)
        @constant_table.delete(sym)
      end

      def define_method(name, proc)
        str_name = name.to_s
        name = name.to_sym
        new_method = LaserMethod.new(str_name, proc)
        new_method.owner = self
        @instance_methods[name] = new_method
        if Bootstrap::VISIBILITY_STACK.value.last == :module_function
          __make_module_function__(name)
        else
          @visibility_table[name] = Bootstrap::VISIBILITY_STACK.value.last
        end
        new_method
      end
      
      def define_method_with_annotations(name, proc, opts={})
        method = define_method(name, proc)
        opts.each { |name, value| method.send("#{name}=", value) }
      end

      def undef_method(symbol)
        sym = symbol.to_sym
        @instance_methods[sym] = nil
        @visibility_table[sym] = :undefined
      end

      def remove_method(symbol)
        sym = symbol.to_sym
        @instance_methods.delete(sym)
        @visibility_table.delete(sym)
      end

      def alias_method(new, old)
        newsym = new.to_sym
        oldsym = old.to_sym
        @instance_methods[newsym] = instance_method(oldsym)
        @visibility_table[newsym] = visibility_for(oldsym)
      end
      
      def include(*mods)
        mods.reverse.each { |mod| include_module(mod) }
      end
      
      def extend(*mods)
        singleton_class.include(*mods)
      end
      
      def __visibility_modifier__(args, kind)
        if args.empty?
          Bootstrap::VISIBILITY_STACK.value[-1] = kind
        else
          args.each { |method| set_visibility!(method.to_sym, kind) }
        end
        self
      end
      
      def __make_module_function__(method_name)
        set_visibility!(method_name, :private)
        found_method = instance_method(method_name).dup
        singleton_class.add_instance_method!(found_method)
        singleton_class.set_visibility!(method_name, :public)
      end
      
      def public(*args)
        __visibility_modifier__(args, :public)
      end
      
      def protected(*args)
        __visibility_modifier__(args, :protected)
      end
      
      def private(*args)
        __visibility_modifier__(args, :private)
      end
      
      def module_function(*args)
        if args.any?
          args.each do |method|
            __make_module_function__(method.to_sym)
          end
        else
          Bootstrap::VISIBILITY_STACK.value[-1] = :module_function
        end
      end
    end
  end
end