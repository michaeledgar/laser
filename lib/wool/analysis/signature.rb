module Wool
  module SexpAnalysis
    class Argument < Struct.new(:name, :kind, :protocol, :default_value_sexp)
    end
    
    module ArgumentListHandling
      # Returns the hash representing the arguments in a signature, based on an
      # argument list (:params) from the parser.
      #
      # @param Sexp arglist
      # @return Symbol => Argument
      def arg_list_for_arglist(arglist)
        arg_list = []
        positional_1, optionals, rest_arg, positional_2, block_arg = arglist.children

        arg_list.concat parse_positionals(positional_1) if positional_1
        arg_list.concat parse_optionals(optionals) if optionals
        arg_list.concat parse_rest_arg(rest_arg) if rest_arg
        arg_list.concat parse_positionals(positional_2) if positional_2
        arg_list.concat parse_block_arg(block_arg) if block_arg
        arg_list
      end
      
      # Adds the positional arguments to the argument hash/list.
      #
      # current_arg_hash: (Symbol => Argument)
      # positional_list: Array<Sexp>
      def parse_positionals(positional_list)
        positional_list.map do |tag, name, lex|
          Argument.new(name, :positional, Protocols::UnknownProtocol.new)
        end
      end
      
      # Parses a list of optional arguments in Sexp form and adds them
      # to the argument hash.
      #
      # current_arg_hash: (Symbol => Argument)
      # optionals: Array<Sexp>
      def parse_optionals(optionals)
        optionals.map do |id, default_value|
          Argument.new(id.children.first, :optional, Protocols::UnknownProtocol.new, default_value)
        end
      end
      
      # Parses the rest argument of an argument list Sexp and adds it to
      # the argument hash.
      #
      # rest_arg: Sexp
      def parse_rest_arg(rest_arg)
        Argument.new(rest_arg[1][1], :rest, ClassRegistry['Array'])
      end
      
      # Parses the block argument of an argument list Sexp and adds it to
      # the argument hash.
      #
      # block_arg: Sexp
      def parse_block_arg(block_arg)
        Argument.new(block_arg[1][1], :block, ClassRegistry['Proc'])
      end
    end
    
    # A single signature in the Wool protocol system. This is just
    # a simple specification of a method that an object can receive,
    # either explicitly or implicitly defined, and the protocols of the
    # return type and all arguments.
    #
    # name: String
    # return_protocol: Protocol
    # arguments: Symbol => Protocol
    class Signature < Struct.new(:name, :return_protocol, :arguments)
      include Comparable
      extend ArgumentListHandling

      def self.for_definition_sexp(arglist, body)
        arg_hash = {}
        arglist = arglist.deep_find { |node| node.type == :params }
        new_signature = Signature.new(name[1], Protocols::UnknownProtocol.new, arg_list_for_arglist(arglist))
      end

      def initialize(*args)
        super
        # validate state
        unless String === self.name && Protocols::Base === self.return_protocol &&
               Array === self.arguments && self.arguments.all? { |v| Argument === v }
          raise ArgumentError.new("Invalid arguments to a signature: #{args.inspect}")
        end
        @argument_hash = Hash[arguments.map {|arg| [arg.name, arg]}]
      end

      # It's trivially clear that equal Signatures have equal mangled forms.
      # It's nice to notice that by using a space as the delimeter, the mangled
      # form is still all visible characters, but also the space will compare less
      # than any other visible character. Thus, when sorted, we can achieve
      # a piecewise comparison purely lexicographically.
      def mangled_form
        "#{name} #{return_protocol} #{arguments.to_a.flatten.map(&:to_s).sort.join(' ')}"
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