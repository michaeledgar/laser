module Laser
  module SexpAnalysis
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
        arg_list << parse_rest_arg(rest_arg) if rest_arg
        arg_list.concat parse_positionals(positional_2) if positional_2
        arg_list << parse_block_arg(block_arg) if block_arg
        arg_list
      end
      
      # Adds the positional arguments to the argument hash/list.
      #
      # current_arg_hash: (Symbol => Argument)
      # positional_list: Array<Sexp>
      # return: Array<Bindings::ArgumentBinding>
      def parse_positionals(positional_list)
        positional_list.map do |node|
          tag, name, lex = node
          result = Bindings::ArgumentBinding.new(name, LaserObject.new, :positional)
          result.ast_node = node
          result
        end
      end
      
      # Parses a list of optional arguments in Sexp form and adds them
      # to the argument hash.
      #
      # current_arg_hash: (Symbol => Argument)
      # optionals: Array<Sexp>
      def parse_optionals(optionals)
        optionals.map do |node|
          id, default_value = node
          result = Bindings::ArgumentBinding.new(id.children.first, LaserObject.new, :optional, default_value)
          result.ast_node = node
          result
        end
      end
      
      # Parses the rest argument of an argument list Sexp and adds it to
      # the argument hash.
      #
      # rest_arg: Sexp
      def parse_rest_arg(rest_arg)
        result = Bindings::ArgumentBinding.new(rest_arg[1][1], LaserObject.new(ClassRegistry['Array']), :rest)
        result.ast_node = rest_arg
        result
      end
      
      # Parses the block argument of an argument list Sexp and adds it to
      # the argument hash.
      #
      # block_arg: Sexp
      def parse_block_arg(block_arg)
        result = Bindings::ArgumentBinding.new(block_arg[1][1], LaserObject.new(ClassRegistry['Proc']), :block)
        result.ast_node = block_arg
        result
      end
    end
    
    # A single signature in the Laser protocol system. This is just
    # a simple specification of a method that an object can receive,
    # either explicitly or implicitly defined, and the protocols of the
    # return type and all arguments.
    #
    # name: String
    # return_type: Protocol
    # arguments: Symbol => Protocol
    Signature = Struct.new(:name, :arguments, :return_type) do
      include Comparable
      extend ArgumentListHandling

      def self.for_definition_sexp(name, arglist, body)
        arg_hash = {}
        arglist = arglist.deep_find { |node| node.type == :params }
        new_signature = Signature.new(name, arg_list_for_arglist(arglist), Types::TOP)
      end

      def initialize(*args)
        super
        # validate state
        unless String === self.name && Types::Base === self.return_type &&
               Array === self.arguments && self.arguments.all? { |v| Bindings::ArgumentBinding === v }
          raise ArgumentError.new("Invalid arguments to a signature: #{args.inspect}")
        end
        @argument_hash = Hash[arguments.map {|arg| [arg.name, arg]}]
      end

      # Returns the arity of the signature.
      def arity
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

      # It's trivially clear that equal Signatures have equal mangled forms.
      # It's nice to notice that by using a space as the delimeter, the mangled
      # form is still all visible characters, but also the space will compare less
      # than any other visible character. Thus, when sorted, we can achieve
      # a piecewise comparison purely lexicographically.
      def mangled_form
        "#{name} #{return_type.inspect} #{arguments.to_a.flatten.map(&:to_s).sort.join(' ')}"
      end

      def <=>(other)
        mangled_form <=> other.mangled_form
      end
    end
  end
end