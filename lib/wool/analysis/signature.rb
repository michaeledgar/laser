module Wool
  module SexpAnalysis
    class Argument < Struct.new(:name, :kind, :protocol, :default_value_sexp)
    end
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

      def self.for_definition_sexp(arglist, body)
        arg_hash = {}
        arglist = arglist.deep_find { |node| node.type == :params }
        new_signature = Signature.new(name[1], Protocols::UnknownProtocol.new, arg_hash_for_arglist(arglist))
      end
      
      # Returns the hash representing the arguments in a signature, based on an
      # argument list (:params) from the parser.
      #
      # @param Sexp arglist
      # @return Symbol => Argument
      def self.arg_hash_for_arglist(arglist)
        arg_hash = {}
        positional_1, optionals, rest_arg, positional_2, blockarg = arglist.children
        if positional_1
          positional_1.each do |tag, name, lex|
            arg_hash[name] = Argument.new(name, :positional, Protocols::UnknownProtocol.new)
          end
        end
        if optionals
          optionals.each do |id, default_value|
            name = id.children.first
            arg_hash[name] = Argument.new(name, :optional, Protocols::UnknownProtocol.new, default_value)
          end
        end
        if rest_arg
          name = rest_arg[1][1]
          arg_hash[name] = Argument.new(name, :rest, ClassRegistry['Array'])
        end
        if positional_2
          positional_2.each do |tag, name, lex|
            arg_hash[name] = Argument.new(name, :positional, Protocols::UnknownProtocol.new)
          end
        end
        if blockarg
          name = blockarg[1][1]
          arg_hash[name] = Argument.new(name, :block, ClassRegistry['Proc'])
        end
        arg_hash
      end

      def initialize(*args)
        super
        # validate state
        unless String === self.name && Protocols::Base === self.return_protocol &&
               Hash === self.argument_protocols &&
               self.argument_protocols.all? { |k, v| String === k && Argument === v }
          raise ArgumentError.new("Invalid arguments to a signature: #{args.inspect}")
        end
      end

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