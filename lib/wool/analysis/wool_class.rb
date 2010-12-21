module Wool
  module SexpAnalysis
    class WoolObject
      extend ModuleExtensions
      attr_reader :protocol, :scope, :methods
      
      def initialize(klass = ClassRegistry['Object'], scope = Scope::GlobalScope)
        @protocol = klass.protocol
        @scope = scope
        @methods = {}
      end
      
      def signatures
        @methods.values.map(&:signatures).flatten
      end
      
      def add_method(method)
        @methods[method.name] = method
      end
    end
    
    # Wool representation of a module. Named WoolModule to avoid naming
    # conflicts. It has lists of methods, instance variables, and so on.
    class WoolModule < WoolObject
      attr_reader :path, :instance_methods, :object
      
      def initialize(full_path, scope = Scope::GlobalScope)
        super(self, scope)
        @path = full_path
        @instance_methods = {}
        @scope = scope
        @methods = {}
        initialize_protocol
        @object = Symbol.new(:protocol => @protocol, :class_used => ClassRegistry[superclass_name], :scope => scope,
                             :name => name, :value => self)
        initialize_scope
        yield self if block_given?
      end

      def superclass_name
        'Module'
      end

      # If this is a new, custom module, we can update the constant
      # table and perform module initialization.
      def initialize_scope
        if @scope && @scope != Scope::GlobalScope
          @scope.self_ptr = self.object
          @scope.parent.constants[name] = self.object if @scope.parent
        end
      end
      
      def initialize_protocol
        if ProtocolRegistry[superclass_name].empty?
          @protocol = Protocols::InstanceProtocol.new(superclass_name)
          ProtocolRegistry.add_class_protocol(@protocol)
        else
          @protocol = ProtocolRegistry[superclass_name].first
        end
        # for instances of me
        ProtocolRegistry.add_class_protocol(Protocols::InstanceProtocol.new(self))
      end
      
      def name
        self.path.split('::').last
      end
      
      def add_instance_method(method)
        @instance_methods[method.name] = method
      end
      
      def inspect
        "#<WoolModule: #{path}>"
      end
    end

    # Wool representation of a class. I named it WoolClass so it wouldn't
    # clash with regular Class. This links the class to its protocol.
    # It inherits from WoolModule to pull in everything but superclasses.
    class WoolClass < WoolModule
      attr_accessor :superclass
      
      def superclass_name
        'Class'
      end
      
      def inspect
        "#<WoolClass: #{path} superclass=#{superclass.inspect}>"
      end
    end

    # Wool representation of a method. This name is tweaked so it doesn't
    # collide with ::Method.
    class WoolMethod
      extend ModuleExtensions
      attr_reader :name, :signatures
      attr_accessor_with_default :pure, false

      def initialize(name)
        @name = name
        @signatures = []
        yield self if block_given?
      end

      def add_signature(return_proto, arg_protos)
        @signatures << Signature.new(self.name, return_proto, arg_protos)
      end
    end
  end
end