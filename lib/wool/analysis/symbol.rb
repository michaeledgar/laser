module Wool
  module SexpAnalysis
    # This class represents a Symbol in Ruby. It may have a known protocol (type),
    # class, value (if constant!), and a variety of other details.
    class Symbol
      include Comparable
      attr_accessor :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end
      
      def <=>(other)
        self.name <=> other.name
      end
      
      def scope
        value.scope
      end
      
      def protocol
        value.protocol
      end
      
      def class_used
        value.klass
      end
      
      def inspect
        "#<Symbol: #{name}>"
      end
    end
  end
end