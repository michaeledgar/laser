require 'pp'
require 'delegate'
module Laser
  module SexpAnalysis
    UNDEFINED = PlaceholderObject.new('UNDEFINED')
    VARYING = PlaceholderObject.new('VARYING')

    module SingletonClassFactory
      def self.create_for(ruby_obj)
        if nil == ruby_obj
          return ClassRegistry['NilClass']
        elsif true == ruby_obj
          return ClassRegistry['TrueClass']
        elsif false == ruby_obj
          return ClassRegistry['FalseClass']
        else
          name = "Instance:#{ruby_obj}"
          existing = ProtocolRegistry[name].first
          existing || LaserSingletonClass.new(
              ClassRegistry['Class'], Scope::GlobalScope, name, ruby_obj) do |new_singleton_class|
            new_singleton_class.superclass = ClassRegistry[ruby_obj.class.name]
          end
        end
      end
    end

    # Catch all representation of an object. Should never have klass <: Module.
    class LaserObject
      extend ModuleExtensions
      attr_reader :scope, :klass, :name
      attr_writer :singleton_class
      def initialize(klass = ClassRegistry['Object'], scope = Scope::GlobalScope,
                     name = "#<#{klass.path}:#{object_id.to_s(16)}>")
        @klass = klass
        @scope = scope
        @name = name
        @instance_variables = Hash.new do |h, k|
          h[k] = Bindings::InstanceVariableBinding.new(k, nil)
        end
      end
      
      def add_instance_method!(method)
        singleton_class.add_instance_method!(method)
      end
      
      def inspect
        return 'main' if self == Scope::GlobalScope.self_ptr
        super
      end
      
      alias path name

      def normal_class
        if @singleton_class
          return @singleton_class.superclass
        else
          return @klass
        end
      end

      def singleton_class
        return @singleton_class if @singleton_class
        new_scope = ClosedScope.new(self.scope, nil)
        @singleton_class = LaserSingletonClass.new(
            ClassRegistry['Class'], new_scope, "Class:#{name}", self) do |new_singleton_class|
          new_singleton_class.superclass = self.klass
        end
        @klass = @singleton_class
      end

      def laser_simulate(method, args, opts={})
        opts = {self: self, mutation: false}.merge(opts)
        klass.instance_method(method).master_cfg.dup.simulate(args, opts)
      end

      def instance_variable_defined?(var)
        @instance_variables.has_key?(var)
      end

      def instance_variable_get(var)
        @instance_variables[var].value
      end

      def instance_variable_set(var, value)
        normal_class.instance_variable(var).inferred_type =
            Types::UnionType.new([normal_class.instance_variable(var).expr_type, 
                                  Utilities.normal_class_for(value).as_type])
        @instance_variables[var].bind!(value)
      end
    end

    class LaserProc < LaserObject
      attr_accessor :ast_node, :arguments, :cfg, :exit_block, :lexical_self
      def initialize(arguments, ast_node, cfg = nil, callsite_block = nil)
        @ast_node = ast_node
        @arguments = arguments
        @cfg = cfg
        @callsite_block = callsite_block
        @lexical_self = @exit_block = nil
      end

      def start_block
        @callsite_block && @callsite_block.block_taken_successors.first
      end

      def inspect
        desc_part = "Proc:0x#{object_id.to_s(16)}@#{ast_node.file_name}"
        arg_part = "(#{arguments.map(&:name).join(', ')})"
        if ast_node.source_begin
          "#<#{desc_part}:#{ast_node.line_number}*#{arg_part}>"
        else
          "#<#{desc_part}*#{arg_part}>"
        end
      end
      alias name inspect

      def compiled_cfg
        return @cfg if @cfg
        # since this is lazily compiling, we should update cref to reflect the runtime
        # value before compiling. hackish.
        if @ast_node.scope.self_ptr == Scope::GlobalScope.self_ptr
          @ast_node.scope.lexical_target = Scope::GlobalScope.lookup('self')
        else
          @ast_node.scope.lexical_target = @ast_node.scope.self_ptr.value.binding
        end
        builder = ControlFlow::GraphBuilder.new(@ast_node, @arguments, @ast_node.scope)
        @cfg = builder.build
      end

      def simulate(args, block, opts={})
        update_cfg_edges(opts) if opts[:invocation_sites]
        self_to_use = opts[:self] || @lexical_self
        cfg.simulate(args, opts.merge({self: self_to_use, block: block, start_block: start_block}))
      end

      def update_cfg_edges(opts)
        opts[:invocation_sites][self].each do |callsite|
          opts[:invocation_counts][self][callsite] += 1
          callsite_succ = callsite.successors.find do |b|
            b.name == start_block.name || b.name.include?("SSA-FIX-#{start_block.name}")
          end
          if !callsite.has_flag?(callsite_succ, RGL::ControlFlowGraph::EDGE_EXECUTABLE)
            callsite.add_flag(callsite_succ, RGL::ControlFlowGraph::EDGE_EXECUTABLE)
          else
            exit_succ = exit_block.successors.find do |b|
              b.name == start_block.name || b.name.include?("SSA-FIX-#{start_block.name}")
            end
            exit_block.add_flag(exit_succ, RGL::ControlFlowGraph::EDGE_EXECUTABLE)
          end
        end
      end
      
      def to_proc
        self
      end

      def call(*args, &blk)
        
      end

      def ssa_cfg
        @ssa_cfg ||= compiled_cfg.static_single_assignment_form
      end

      def klass
        ClassRegistry['Proc']
      end
    end
    
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
        @instance_methods[method.name] = method
        @visibility_table[method.name] = :public
        method.owner = self
      end

      def instance_method(name)
        if @instance_methods.has_key?(name.to_s)
        then @instance_methods[name.to_s]
        else @superclass && @superclass.instance_method(name)
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
        mine = @instance_methods.keys.map(&:to_sym)
        if include_super && @superclass
        then @superclass.instance_methods | mine
        else mine
        end
      end

      def instance_methods(include_super = true)
        methods = __all_instance_methods(include_super)
        table = visibility_table
        methods.select { |name| table[name.to_s] == :public || table[name.to_s] == :protected }
      end

      def public_instance_methods(include_super = true)
        methods = __all_instance_methods(include_super)
        table = visibility_table
        methods.select { |name| table[name.to_s] == :public }
      end
      
      def protected_instance_methods(include_super = true)
        methods = __all_instance_methods(include_super)
        table = visibility_table
        methods.select { |name| table[name.to_s] == :protected }
      end
      
      def protected_method_defined?(name)
        methods = __all_instance_methods(include_super)
        table = visibility_table
        methods.select { |name| table[name.to_s] == :protected }
      end
      
      def private_instance_methods(include_super = true)
        methods = __all_instance_methods(include_super)
        table = visibility_table
        methods.select { |name| table[name.to_s] == :private }
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
        return @visibility_table[method] ||
          (@superclass && @superclass.visibility_for(method))
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
        name = name.to_s
        new_method = LaserMethod.new(name, proc)
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
        @instance_methods[symbol.to_s] = nil
        @visibility_table[symbol.to_s] = :undefined
      end

      def remove_method(symbol)
        @instance_methods.delete(symbol.to_s)
        @visibility_table.delete(symbol.to_s)
      end

      def alias_method(new, old)
        @instance_methods[new.to_s] = @instance_methods[old.to_s]
        @visibility_table[new.to_s] = @visibility_table[old.to_s]
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
          args.each { |method| set_visibility!(method.to_s, kind) }
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
            __make_module_function__(method.to_s)
          end
        else
          Bootstrap::VISIBILITY_STACK.value[-1] = :module_function
        end
      end
    end

    # Laser representation of a class. I named it LaserClass so it wouldn't
    # clash with regular Class. This links the class to its protocol.
    # It inherits from LaserModule to pull in everything but superclasses.
    class LaserClass < LaserModule
      attr_reader :subclasses
      
      def initialize(klass = ClassRegistry['Class'], scope = Scope::GlobalScope,
                     full_path=(@name_set = :no; "#{klass.path}:Anonymous:#{object_id.to_s(16)}"))
        @subclasses ||= []
        # bootstrapping exception
        unless ['Class', 'Module', 'Object', 'BasicObject'].include?(full_path)
          @superclass = ClassRegistry['Object']
        end
        super # can yield, so must come last
      end
      
      def normal_class
        return ClassRegistry['Class']
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
        if LaserModuleCopy === other # || LaserSingletonClass === self
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
      
      def instance_method(name)
        return @delegated.instance_method(name.to_s) ||
          (@superclass && @superclass.instance_method(name))
      end
      
      def visibility_for(method)
        return @delegated.visibility_for(method) ||
          (@superclass && @superclass.visibility_for(method))
      end

      def instance_methods(include_superclass = true)
        if include_superclass && @superclass
        then @superclass.instance_methods | @delegated.instance_methods
        else @delegated.instance_methods
        end
      end
    end

    # Laser representation of a method. This name is tweaked so it doesn't
    # collide with ::Method.
    class LaserMethod
      extend ModuleExtensions
      attr_reader :name
      attr_reader :proc
      attr_accessor :body_ast, :owner, :arity
      attr_accessor_with_default :overloads, {}
      attr_accessor_with_default :annotated_return, nil
      attr_accessor_with_default :special, false
      attr_accessor_with_default :builtin, false
      attr_accessor_with_default :mutation, false
      attr_accessor_with_default :pure, false
      attr_accessor_with_default :predictable, true
      attr_accessor_with_default :raises, nil
      attr_accessor_with_default :annotated_raise_frequency, nil
      attr_accessor_with_default :annotated_yield_usage, nil

      # Gets the laser method with the given class and name. Convenience for
      # debugging/quick access.
      def self.for(name)
        if name.include?('.')
          klass, method = name.split('.', 2)
          Scope::GlobalScope.lookup(klass).value.singleton_class.instance_method(method)
        elsif name.include?('#')
          klass, method = name.split('#', 2)
          Scope::GlobalScope.lookup(klass).value.instance_method(method)
        else
          raise ArgumentError.new("method '#{name}' should be in the form Class#instance_method or Class.singleton_method.")
        end
      end

      def initialize(name, base_proc)
        @name = name
        @type_instantiations = {}
        @proc = base_proc
        if base_proc
          @arity = Arity.for_arglist(base_proc.arguments)
        else
          @arity = nil
        end  
        yield self if block_given?
      end
      
      def yield_type
        return @annotated_yield_usage if @annotated_yield_usage
        if builtin
          :ignored
        else
          master_cfg.analyze
          master_cfg.yield_type
        end
      end
      
      def yield_arity
        master_cfg.analyze
        master_cfg.yield_arity
      end
      
      def raise_frequency_for_types(self_type, arg_types = [], block_type = nil)
        block_type ||= Types::NILCLASS
        return annotated_raise_frequency if annotated_raise_frequency
        return Frequency::MAYBE if builtin || special
        cfg_for_types(self_type, arg_types, block_type).raise_frequency
      end
      
      def raise_type_for_types(self_type, arg_types = [], block_type = nil)
        block_type ||= Types::NILCLASS
        Laser.debug_puts("Calculating raise type for #{owner.name}##{name} with types "+
                         "#{self_type.inspect} #{arg_types.inspect} #{block_type.inspect}")
        if raises
          Laser.debug_puts("Raise type is annotated: #{self.raises.inspect}")
          return self.raises 
        end
        if builtin || special
          if annotated_raise_frequency == Frequency::NEVER
            self.raises = Types::EMPTY
            Laser.debug_puts("Raise type is annotated: #{self.raises.inspect}")
            return self.raises
          end
          Laser.debug_puts("Builtin/special: Types::TOP")
          return Types::TOP
        end
        cfg_for_types(self_type, arg_types, block_type).raise_type
      end
      
      def return_type_for_types(self_type, arg_types = [], block_type = nil)
        block_type ||= Types::NILCLASS
        return self.annotated_return if annotated_return
        unless overloads.empty?
          overloads.each do |overload_args, proc_type|
            # compatible arg count
            if overload_args.size == arg_types.size
              # all types unify?
              if overload_args.zip(arg_types).all? { |spec, concrete| Types.subtype?(concrete, spec) }
                return proc_type.subtypes[1]
              end
            end
          end
          raise TypeError.new("No overload found for #{self.inspect} with arg types #{arg_types.inspect}")
        end
        return Types::TOP if builtin || special
        result = cfg_for_types(self_type, arg_types, block_type).return_type
        check_return_type_against_expectations(result)
        result
      end

      def check_return_type_against_expectations(return_type)
        if (expectation = Types::EXPECTATIONS[self.name]) &&
            !Types.subtype?(return_type, expectation)
          @proc.ast_node.add_error(ImproperOverloadTypeError.new(
            "All methods named #{self.name} should return a subtype of #{expectation.inspect}",
            @proc.ast_node))
        end
      end

      def master_cfg
        @master_cfg ||= @proc.ssa_cfg.tap do |cfg|
          cfg.bind_self_type(Types::ClassType.new(owner.path, :covariant))
        end
      end
      
      def cfg_for_types(self_type, arg_types = [], block_type = nil)
        block_type ||= Types::NILCLASS
        Laser.debug_puts("Calculating CFG(#{owner.name}##{name}, #{self_type.inspect}, #{arg_types.inspect}, #{block_type.inspect})")
        @type_instantiations[[self_type, *arg_types, block_type]] ||= master_cfg.dup.tap do |cfg|
          cfg.bind_self_type(self_type)
          cfg.bind_formal_types(arg_types)
          cfg.bind_block_type(block_type)
          cfg.analyze
        end
      end

      def simulate_with_args(new_self, args, block, opts)
        self_type = Utilities.type_for(new_self)
        formal_types = args.map { |arg| Utilities.type_for(arg) }
        block_type = Utilities.type_for(block)
        cfg_for_types(self_type, formal_types, block_type).dup.simulate(
            args, opts.merge(self: new_self, block: block, start_block: @proc.start_block))
      end

      def arguments
        @proc.arguments
      end

      def dup
        result = LaserMethod.new(name, proc)
        result.body_ast = self.body_ast
        result.owner = self.owner
        result.arity = self.arity
        result
      end
      
      def refine_arity(new_arity)
        return new_arity if @arity.nil?
        new_begin = [new_arity.begin, @arity.begin].min
        new_end = [new_arity.end, @arity.end].max
        new_begin..new_end
      end
    end
  end
end
