module Wool
  module SexpAnalysis
    # Wool representation of a class. I named it WoolClass so it wouldn't
    # clash with regular Class. This links the class to its protocol. It
    # has lists of methods, instance variables, and so on.
    class WoolClass
      attr_reader :path, :methods, :protocol, :scope, :class_object
      attr_accessor :superclass

      def initialize(full_path, scope = Scope::GlobalScope)
        @path = full_path
        @methods = {}
        @protocol = Protocols::ClassProtocol.new(self)
        @scope = scope
        @class_object = Symbol.new(@protocol, self)
        yield self if block_given?
      end
      
      def add_method(method)
        @methods[method.name] = method
      end
      
      def signatures
        @methods.values.map(&:signatures).flatten
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