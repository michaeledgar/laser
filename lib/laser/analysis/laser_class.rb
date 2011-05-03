        require 'pp'
require 'delegate'
module Laser
  module SexpAnalysis
    # This is the path through which objects should be instantiated. It uses
    # case-by-case logic to handle the instantiation of LaserModule/LaserClass
    # when necessary.
    module LiveObjectRepresentation
      def self.new(klass, *args, &blk)
        if klass == ClassRegistry['Class']
          LaserClass.new(klass, *args, &blk)
        elsif klass.ancestors.include?(ClassRegistry['Module'])
          LaserModule.new(klass, *args, &blk)
        else
          LaserObject.new(klass, *args, &blk)
        end
      end
    end

    module BasicLaserObjectBehavior
      attr_reader :scope, :klass, :name
      attr_writer :singleton_class
      def initialize(klass = ClassRegistry['Object'], scope = Scope::GlobalScope,
                     name = "#<#{klass.path}:#{object_id.to_s(16)}>")
        @klass = klass
        @scope = scope
        @name = name
      end
      
      def add_instance_method!(method)
        singleton_class.add_instance_method!(method)
      end
      
      def add_signature!(signature)
        singleton_class.add_signature!(signature)
      end
      
      def inspect
        return 'main' if self == Scope::GlobalScope.self_ptr
        super
      end
      
      alias path name
      
      def singleton_class
        return @singleton_class if @singleton_class
        new_scope = ClosedScope.new(self.scope, nil)
        @singleton_class = LaserSingletonClass.new(
            ClassRegistry['Class'], new_scope, "Class:#{name}", self) do |new_singleton_class|
          new_singleton_class.superclass = self.klass
        end
        @klass = @singleton_class
      end
      
      def signatures
        singleton_class.instance_signatures
      end
    end
    
    # Catch all representation of an object. Should never have klass <: Module.
    class LaserObject
      extend ModuleExtensions
      include BasicLaserObjectBehavior
    end
    
    class RealObjectProxy < BasicObject
      # Allow updating of scope after the creation of the object, since these
      # constants are discovered very early in the annotation process.
      attr_reader :raw_object
      attr_writer :scope
      include BasicLaserObjectBehavior
      
      def self.careful_forward(*args)
        args.each do |arg|
          define_method arg do |other|
            if RealObjectProxy === other
            then @raw_object.send(arg, other.raw_object)
            else @raw_object.send(arg, other)
            end
          end
        end
      end
      
      def initialize(klass, scope, name, raw_object)
        super(klass, scope, name)
        @raw_object = raw_object
      end
      careful_forward :==, :eql?, :equal?

      def method_missing(meth, *args, &blk)
        @raw_object.send(meth, *args, &blk)
      end
    end
    
    # Laser representation of a module. Named LaserModule to avoid naming
    # conflicts. It has lists of methods, instance variables, and so on.
    class LaserModule < LaserObject
      attr_reader :path, :binding, :superclass
      cattr_accessor_with_default :all_modules, []
      
      def initialize(klass = ClassRegistry['Module'], scope = Scope::GlobalScope,
                     full_path="#{klass.path}:Anonymous:#{object_id.to_s(16)}")
        super(klass, scope, full_path.split('::').last)
        full_path = submodule_path(full_path) if scope && scope.parent
        validate_module_path!(full_path) unless LaserSingletonClass === self
        
        @path = full_path
        @instance_methods = {}
        @instance_variables = {}
        @visibility_table = {}
        @constant_table = {}
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

      def trivial?
        @instance_methods.empty?
      end
      opposite_method :nontrivial?, :trivial?
      
      def add_instance_method!(method)
        @instance_methods[method.name] = method
        method.owner = self
      end
      
      def alias_instance_method!(new, old)
        @instance_methods[new] = @instance_methods[old]
        @visibility_table[new] = @visibility_table[old]
      end

      def public_instance_methods
        methods = instance_methods
        table = visibility_table
        methods.select { |name, _| table[name] == :public }
      end

      def instance_methods(include_superclass = true)
        if include_superclass && @superclass
        then @superclass.instance_methods.merge(@instance_methods)
        else @instance_methods
        end
      end
      
      def instance_signatures
        instance_methods.values.map(&:signatures).flatten
      end
      
      def add_signature!(signature)
        @instance_methods[signature.name].add_signature!(signature)
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
      
      def visibility_table
        if @superclass
        then @superclass.visibility_table.merge(@visibility_table)
        else @visibility_table
        end
      end
      
      def set_visibility!(method, visibility)
        @visibility_table[method] = visibility
      end
      
      def get_instance(scope = self.scope)
        LiveObjectRepresentation.new(self, scope)
      end
      
      def superclass=(new_superclass)
        @superclass = new_superclass
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
          raise UselessIncludeError.new("Included #{original_mod.path} into #{self.path}"+
                                        " but it was already included.", nil)
        end
      end
      
      def inspect
        "#<LaserModule: #{path}>"
      end
      
      # simulation methods
      def const_set(string, value)
        @constant_table[string] = value
      end
      
      def const_get(constant, inherit=true)
        if inherit && @superclass
          @constant_table[constant] || @superclass.const_get(constant, true)
        else
          @constant_table[constant] or raise ArgumentError.new("Class #{@full_path} has no constant #{constant}")
        end
      end
      
      def const_defined?(constant, inherit=true)
        if inherit && @superclass
          !!(@constant_table[constant] || @superclass.const_defined?(constant, inherit))
        else
          !!@constant_table[constant]
        end
      rescue
        false
      end
    end

    # Laser representation of a class. I named it LaserClass so it wouldn't
    # clash with regular Class. This links the class to its protocol.
    # It inherits from LaserModule to pull in everything but superclasses.
    class LaserClass < LaserModule
      attr_reader :subclasses
      
      def initialize(klass = ClassRegistry['Class'], scope = Scope::GlobalScope,
                     full_path="#{klass.path}:Anonymous:#{object_id.to_s(16)}")
        @subclasses ||= []
        # bootstrapping exception
        unless ['Class', 'Module', 'Object', 'BasicObject'].include?(full_path)
          @superclass = ClassRegistry['Object']
        end
        super # can yield, so must come last
      end
      
      def singleton_class
        return @singleton_class if @singleton_class
        new_scope = ClosedScope.new(self.scope, nil)
        @singleton_class = LaserSingletonClass.new(
            ClassRegistry['Class'], new_scope, "Class:#{name}", self) do |new_singleton_class|
          if superclass
            new_singleton_class.superclass = superclass.singleton_class
          else
            new_singleton_class.superclass = ClassRegistry['Class']
          end 
        end
        @klass = @singleton_class
      end
      
      # Adds a subclass.
      def add_subclass!(other)
        subclasses << other
      end
      
      # Removes a subclass.
      def remove_subclass!(other)
        subclasses.delete other
      end
      
      def superclass
        current = @superclass
        while current
          if LaserModuleCopy === current
            current = current.superclass
          else
            return current
          end
        end
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
      
      # The set of all superclasses (including the class itself). Excludes modules.
      def superset
        if superclass.nil?
        then [self]
        else [self] + superclass.superset
        end
      end
      
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
      def initialize(klass, scope, path, instance_or_name)
        super(klass, scope, path)
        # Dirty hook for the magic singletons: nil, true, false.
        if String === instance_or_name
          result = LaserObject.new(self, scope, instance_or_name)
          result.singleton_class = self
          @singleton_instance = result
        else
          @singleton_instance = instance_or_name
        end
      end
      def get_instance(scope=nil)
        singleton_instance
      end
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
        if @superclass.nil?
        then [self]
        else [self] + @superclass.ancestors
        end
      end
      
      def instance_variables
        @delegated.instance_variables
      end
      
      def instance_methods(include_superclass = true)
        if include_superclass && @superclass
        then @superclass.instance_methods.merge(@delegated.instance_methods)
        else @delegated.instance_methods
        end
      end
    end

    # Laser representation of a method. This name is tweaked so it doesn't
    # collide with ::Method.
    class LaserMethod
      extend ModuleExtensions
      attr_reader :name
      attr_accessor :body_ast, :owner, :signatures, :arity
      attr_accessor_with_default :special, false
      attr_accessor_with_default :builtin, false
      attr_accessor_with_default :mutation, false
      attr_accessor_with_default :pure, false
      attr_accessor_with_default :predictable, true
      attr_accessor_with_default :raises, []
      attr_accessor_with_default :raise_type, Frequency::MAYBE

      # Gets the laser method with the given class and name. Convenience for
      # debugging/quick access.
      def self.for(name)
        if name.include?('.')
          klass, method = name.split('.', 2)
          Scope::GlobalScope.lookup(klass).value.singleton_class.instance_methods[method]
        elsif name.include?('#')
          klass, method = name.split('#', 2)
          Scope::GlobalScope.lookup(klass).value.instance_methods[method]
        else
          raise ArgumentError.new("method '#{name}' should be in the form Class#instance_method or Class.singleton_method.")
        end
      end

      def initialize(name)
        @name = name
        @signatures = []
        @arity = nil
        yield self if block_given?
      end

      def dup
        result = LaserMethod.new(name)
        result.body_ast = self.body_ast
        result.owner = self.owner
        result.signatures = self.signatures
        result.arity = self.arity
        result
      end

      def cfg
        ControlFlow::GraphBuilder.new(self.body_ast.deep_find { |node| node.type == :bodystmt }).build
      end

      def add_signature!(signature)
        @signatures << signature
        @arity = Arity.new(refine_arity(signature.arity))
      end
      
      def refine_arity(new_arity)
        return new_arity if @arity.nil?
        new_begin = [new_arity.begin, @arity.begin].min
        new_end = [new_arity.end, @arity.end].max
        new_begin..new_end
      end
      
      def empty?
        signatures.empty?
      end
    end
  end
end