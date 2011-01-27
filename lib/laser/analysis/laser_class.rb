require 'delegate'
module Laser
  module SexpAnalysis
    class LaserObject
      extend ModuleExtensions
      attr_reader :protocol, :scope, :klass, :name
      
      def initialize(klass = ClassRegistry['Object'], scope = Scope::GlobalScope,
                     name = "#<#{klass.path}:#{object_id.to_s(16)}>")
        @klass = klass
        @protocol = klass.protocol
        @scope = scope
        @name = name
      end
      
      def add_instance_method!(method)
        singleton_class.add_instance_method!(method)
      end
      
      def add_signature!(signature)
        singleton_class.add_signature!(signature)
      end
      
      def singleton_class
        return @singleton_class if @singleton_class
        new_scope = ClosedScope.new(self.scope, nil)
        @singleton_class = LaserSingletonClass.new("Class:#{name}", new_scope, self) do |new_singleton_class|
          new_singleton_class.superclass = self.klass
        end
        @singleton_class
      end
      
      def signatures
        singleton_class.instance_signatures
      end
    end
    
    # Laser representation of a module. Named LaserModule to avoid naming
    # conflicts. It has lists of methods, instance variables, and so on.
    class LaserModule < LaserObject
      attr_reader :path, :instance_methods, :binding, :superclass
      cattr_accessor_with_default :all_modules, []
      
      def initialize(full_path, scope = Scope::GlobalScope)
        super(self, scope)
        full_path = submodule_path(full_path) if scope && scope.parent
        validate_module_path!(full_path)
        
        @path = full_path
        @instance_methods = Hash.new { |hash, name| hash[name] = LaserMethod.new(name) }
        @scope = scope
        @methods = {}
        @superclass ||= nil
        initialize_protocol
        @binding = Bindings::ConstantBinding.new(name, self)
        initialize_scope
        yield self if block_given?
        LaserModule.all_modules << self
      end

      # Returns the canonical path for a (soon-to-be-created) submodule of the given
      # scope. This is computed before creating the module.
      def submodule_path(new_mod_name)
        scope = self.scope.parent
        new_mod_full_path = scope == Scope::GlobalScope ? '' : scope.path
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

      def klass
        ClassRegistry[class_name]
      end
      
      def class_name
        'Module'
      end

      # If this is a new, custom module, we can update the constant
      # table and perform module initialization.
      def initialize_scope
        if @scope && @scope != Scope::GlobalScope
          @scope.self_ptr = self.binding.value
          @scope.parent.constants[name] = self.binding if @scope.parent
          @scope.locals['self'] = self.binding
        end
      end
      
      # Initializes the protocol for this LaserClass.
      def initialize_protocol
        if ProtocolRegistry[path].any? && !TESTS_ACTIVATED
          $stderr.puts "Warning: creating new instance of #{class_name} #{path}"
          @protocol = ProtocolRegistry[path].first
        else
          @protocol = Protocols::InstanceProtocol.new(self)
          ProtocolRegistry.add_class_protocol(@protocol)
        end
      end
      
      def name
        self.path.split('::').last
      end

      def trivial?
        @instance_methods.empty?
      end
      opposite_method :nontrivial?, :trivial?
      
      def add_instance_method!(method)
        @instance_methods[method.name] = method
      end
      
      def instance_signatures
        instance_methods.values.map(&:signatures).flatten
      end
      
      def add_signature!(signature)
        @instance_methods[signature.name].add_signature!(signature)
      end
      
      def get_instance
        LaserObject.new(self, nil)
      end
      
      def superclass=(new_superclass)
        @superclass = new_superclass
      end
      
      # The set of all superclasses (including the class itself)
      def ancestors
        if superclass.nil?
        then [self]
        else [self] + superclass.ancestors
        end
      end
      
      # Directly translated from MRI's C implementation in class.c:650
      def include_module(mod)
        if mod.klass == ClassRegistry['Class']
          raise ArgumentError.new("Tried to include #{mod.name}, which should "+
                                  " be a Module or Module subclass, not a " +
                                  "#{mod.klass.name}.")
        end
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
            current = (current.superclass = LaserModuleCopy.new(mod, current.superclass))
          end
          mod = mod.superclass
        end
      end
      
      def inspect
        "#<LaserModule: #{path}>"
      end
    end

    # Laser representation of a class. I named it LaserClass so it wouldn't
    # clash with regular Class. This links the class to its protocol.
    # It inherits from LaserModule to pull in everything but superclasses.
    class LaserClass < LaserModule
      attr_reader :subclasses
      
      def initialize(*args)
        @subclasses ||= []
        # bootstrapping exception
        unless ['Class', 'Module', 'Object'].include?(args.first)
          @superclass = ClassRegistry['Object']
        end
        super # can yield, so must come last
      end
      
      def singleton_class
        return @singleton_class if @singleton_class
        new_scope = ClosedScope.new(self.scope, nil)
        @singleton_class = LaserSingletonClass.new("Class:#{name}", new_scope, self) do |new_singleton_class|
          if superclass
            new_singleton_class.superclass = superclass.singleton_class
          else
            new_singleton_class.superclass = ClassRegistry['Class']
          end 
        end
      end
      
      # Adds a subclass.
      def add_subclass!(other)
        subclasses << other
      end
      
      # Removes a subclass.
      def remove_subclass!(other)
        subclasses.delete other
      end
      
      # Sets the superclass, which handles registering/unregistering subclass
      # ownership elsewhere in the inheritance tree
      def superclass=(other)
        if LaserModuleCopy === other
          @superclass = other
        else
          superclass.remove_subclass! self if superclass
          @superclass = other
          superclass.add_subclass! self
        end
      end
      
      # The set of all superclasses (including the class itself)
      alias_method :superset, :ancestors
      
      # The set of all superclasses (excluding the class itself)
      def proper_superset
        superset - [self]
      end
      
      # The set of all subclasses (including the class itself)
      def subset
        [self] + subclasses.map(&:subset).flatten
      end
      
      # The set of all subclasses (excluding the class itself)
      def proper_subset
        subset - [self]
      end
      
      def instance_methods
        if superclass
        then superclass.instance_methods.merge(@instance_methods)
        else @instance_methods
        end
      end
      
      def class_name
        'Class'
      end
      
      def inspect
        "#<LaserClass: #{path} superclass=#{superclass.inspect}>"
      end
    end

    # Singleton classes are important to model separately: they only have one
    # instance! Plus, the built-in classes have some oddities: TrueClass is
    # actually a singleton class, not a normal class. true is its singleton
    # object.
    class LaserSingletonClass < LaserClass
      attr_reader :singleton_instance
      def initialize(path, scope, instance)
        super(path, scope)
        @singleton_instance = instance
      end
      alias_method :get_instance, :singleton_instance
    end

    # When you include a module in Ruby, it uses inheritance to model the
    # relationship with the included module. This is how Ruby achieves
    # multiple inheritance. However, to avoid destroying the tree shape of
    # the inheritance hierarchy, when you include a module, it is *copied*
    # and inserted between the current module/class and its superclass.
    # It is marked as a T_ICLASS instead of a T_CLASS because it is an
    # "internal", invisible class: it shouldn't show up when you use #superclass.
    #
    # Yes, that means even modules have superclasses. There's just no method
    # to expose them because a module only ever has a null superclass or a
    # copied-module superclass.
    class LaserModuleCopy < DelegateClass(LaserClass)
      attr_reader :delegated
      def initialize(module_to_copy, with_super)
        super(module_to_copy)
        case module_to_copy
        when LaserModuleCopy then @delegated = module_to_copy.delegated
        else @delegated = module_to_copy
        end
        @superclass = with_super
      end
      
      def superclass
        @superclass
      end
      
      def superclass=(other)
        @superclass = other
      end
      
      def ==(other)
        case other
        when LaserModuleCopy then @delegated == other.delegated
        else @delegated == other
        end
      end
      
      # Redefined because otherwise it'll get delegated. Meh.
      # TODO(adgar): Find a better solution than just copy-pasting this method.
      def ancestors
        if superclass.nil?
        then [self]
        else [self] + superclass.ancestors
        end
      end
    end

    # Laser representation of a method. This name is tweaked so it doesn't
    # collide with ::Method.
    class LaserMethod
      extend ModuleExtensions
      attr_reader :name, :signatures
      attr_accessor_with_default :pure, false

      def initialize(name)
        @name = name
        @signatures = []
        yield self if block_given?
      end

      def add_signature!(signature)
        @signatures << signature
      end
    end
  end
end