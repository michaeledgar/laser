module Laser
  module SexpAnalysis
    # This class handles the interpretation and expansion of arguments being
    # passed to a method call.
    class ArgumentExpansion
      attr_reader :node
      # @node can end up either being nil, for no args at all, or an
      # args_add_block node.
      def initialize(node)
        node = node[1] if !node.nil? && node.type == :arg_paren
        @node = node
      end

      # Returns whether the node has a block argument. If it does, it
      # returns the block argument's node.
      def has_block?
        if node.nil?
          false
        elsif node.type == :args_add_block
          node[2]
        end
      end

      # Returns the arity of the argument block being passed, as a range of
      # possible values.
      def arity
        return Arity::EMPTY if node.nil?
        Arity.new(arity_for_node(node))
      end

      # Are there no arguments being passed?
      def empty?
        arity == (0..0)
      end

      # Returns whether all arguments are constant.
      def is_constant?
        return true if node.nil?
        node_is_constant?(node)
      end

      # Returns an array of constant values that are the arguments being passed.
      #
      # pre-contract: is_constant?.should be_true
      def constant_values
        return [] if node.nil?
        node_constant_values(node)
      end

      private

      # Finds the arity of a given argument node.
      def arity_for_node(node)
        case node[0]
        when Array
          node.inject(0..0) { |acc, cur| range_add(acc, arity_for_node(cur)) }
        when :args_add_block
          arity_for_node(node[1])
        when :args_add_star
          initial = arity_for_node(node[1])
          star_arity = arity_for_star(node[2])
          extra = node.size > 3 ? arity_for_node(node[3..-1]) : (0..0)
          range_add(range_add(initial, star_arity), extra)
        else
          1..1
        end
      end
      
      # Adds two ranges together.
      def range_add(r1, r2)
        (r1.begin + r2.begin)..(r1.end + r2.end)
      end
      
      # Finds the arity for a splatted argument. If it's a constant value, we can
      # compute its value 
      def arity_for_star(node)
        if node.is_constant
          ary = node.constant_value.to_a rescue [node.constant_value]
          size = ary.size
          size..size
        else
          0..Float::INFINITY
        end
      end
      
      # Determines whether a given arg AST node is constant.
      def node_is_constant?(node)
        case node[0]
        when nil then true
        when Array then node.all? { |child| node_is_constant?(child) }
        when :args_add_block
          node[2] ? node_is_constant?(node[1..2]) : node_is_constant?(node[1])
        when :args_add_star then node.children.all? { |child| node_is_constant?(child) }
        else node.is_constant
        end
      end
      
      # Determines the constant values of all arguments being passed, expanding
      # splats.
      def node_constant_values(node)
        case node[0]
        when nil then []
        when Array then node.map { |child| node_constant_values(child) }
        when :args_add_block
          node_constant_values(node[1])
        when :args_add_star
          pre_args = node_constant_values(node[1])
          splat_arg = node_constant_values(node[2])
          real_splat_ary = splat_arg.to_a rescue [splat_arg]
          post_args = node_constant_values(node[3..-1])
          pre_args + real_splat_ary + post_args
        else node.constant_value
        end
      end
    end
  end
end