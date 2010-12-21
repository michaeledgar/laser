module Wool
  module SexpAnalysis
    # This class represents a Symbol in Ruby. It may have a known protocol (type),
    # class, value (if constant!), and a variety of other details.
    class Symbol < Struct.new(:protocol, :class_used, :scope, :name, :value)
      include Comparable
      alias_method :old_initialize, :initialize

      def initialize(*args)
        if args.size == 1 && Hash === args.first
          old_initialize(*args.first.values_at(*self.class.members))
        else
          old_initialize(*args)
        end
      end
      
      def <=>(other)
        self.name <=> other.name
      end
      
      def inspect
        "#<Symbol: #{name}>"
      end
    end
  end
end