module Wool
  module SexpAnalysis
    # A single signature in the Wool protocol system. This is just
    # a simple specification of a method that an object can receive,
    # either explicitly or implicitly defined, and the protocols of the
    # return type and all arguments.
    #
    # name: String
    # return_protocol: Protocol
    # argument_protocols: Symbol => Protocol
    class Signature < Struct.new(:name, :return_protocol, :argument_protocols)
      include Comparable

      # It's trivially clear that equal Signatures have equal mangled forms.
      # It's nice to notice that by using a space as the delimeter, the mangled
      # form is still all visible characters, but also the space will compare less
      # than any other visible character. Thus, when sorted, we can achieve
      # a piecewise comparison purely lexicographically.
      def mangled_form
        "#{name} #{return_protocol} #{argument_protocols.to_a.flatten.map(&:to_s).sort.join(' ')}"
      end

      def hash
        mangled_form.hash
      end

      def <=>(other)
        mangled_form <=> other.mangled_form
      end
    end
  end
end