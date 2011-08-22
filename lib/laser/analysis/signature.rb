module Laser
  module Analysis
    module ArgumentListHandling
      # Returns the hash representing the arguments in a signature, based on an
      # argument list (:params) from the parser.
      #
      # @param Sexp arglist
      # @return Symbol => Argument
      def arg_list_for_arglist(arglist)
        arglist = arglist.deep_find { |node| node.type == :params }
        positional_1, optionals, rest_arg, positional_2, block_arg = arglist.children
        arg_list = []

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
          result = Bindings::ArgumentBinding.new(name, LaserObject.new(ClassRegistry['BasicObject']), :positional)
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
          result = Bindings::ArgumentBinding.new(id.children.first, LaserObject.new(ClassRegistry['BasicObject']), :optional, default_value)
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
    
    module Signature
      include Comparable
      extend ArgumentListHandling
    end
  end
end