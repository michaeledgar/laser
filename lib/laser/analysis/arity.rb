module Laser
  module SexpAnalysis
    # The arity of a method is an instance of Arity. It's basically a range
    # with some helper methods.
    class Arity < Range
      # arguments: [Binding::GenericBinding]
      def self.for_arglist(arguments)
        min, max = 0, 0
        arguments.each do |arg|
          case arg.kind
          when :positional
            min += 1
            max += 1
          when :optional
            max += 1
          when :rest
            max = Float::INFINITY
          end
        end
        min..max
      end
      
      def initialize(range)
        super(range.begin, range.end, range.exclude_end?)
      end
      
      def compatible?(other)
        self.first <= other.last && other.first <= self.last
      end
      EMPTY = Arity.new(0..0)
      ANY = Arity.new(0..Float::INFINITY)
    end
  end
end