module Wool
  module SexpAnalysis
    # This class models a scope in Ruby. It has a constant table,
    # a self pointer, and a parent pointer to the enclosing scope.
    # It also has a local variable table.
    class Scope
      attr_reader :constants, :self_ptr, :parent
      def initialize(parent, self_ptr, constants=[])
        @parent, @self_ptr, @constants = parent, self_ptr, constants
      end
      
      GlobalScope = Scope.new(nil, Symbol.new(ProtocolRegistry['Object']))
    end
  end
end