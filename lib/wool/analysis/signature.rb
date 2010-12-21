module Wool
  module SexpAnalysis
    # A single signature in the Wool protocol system. This is just
    # a simple specification of a method that an object can receive,
    # either explicitly or implicitly defined, and the protocols of the
    # return type and all arguments.
    class Signature < Struct.new(:name, :return_protocol, :argument_protocols)
      include Comparable

      def <=>(other)
        [self.name, self.return_protocol.to_s, self.argument_protocols.map(&:to_s).sort] <=>
            [other.name, other.return_protocol.to_s, other.argument_protocols.map(&:to_s).sort]
      end
    end
  end
end