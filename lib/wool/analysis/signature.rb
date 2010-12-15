module Wool
  module SexpAnalysis
    # A single signature in the Wool protocol system. This is just
    # a simple specification of a method that an object can receive,
    # either explicitly or implicitly defined, and the protocols of the
    # return type and all arguments.
    class Signature < Struct.new(:name, :return_protocol, :argument_protocols)
      include Comparable

      def <=>(other)
        [self.name, self.return_protocol, self.argument_protocols] <=>
            [other.name, other.return_protocol, other.argument_protocols]
      end
    end
  end
end