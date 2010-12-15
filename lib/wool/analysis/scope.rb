module Wool
  module SexpAnalysis
    # This class models a scope in Ruby. It has a constant table,
    # a self pointer, and a parent pointer to the enclosing scope.
    # It also has a local variable table.
    class Scope
      attr_reader :constants, :self_ptr, :parent
      def initialize(parent, self_ptr, constants={})
        @parent, @self_ptr, @constants = parent, self_ptr, constants
      end

      def self.initialize_global_scope
        object_class = WoolClass.new('Object')
        ProtocolRegistry.register_class_protocol(object_class.protocol)
        global = Scope.new(nil, Symbol.new(object_class), {'Object' => object_class})
      end
      GlobalScope = initialize_global_scope
    end
  end
end