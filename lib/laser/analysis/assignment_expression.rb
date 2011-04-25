module Laser
  module SexpAnalysis
    # Entry point for creating a new LHS Expression. This dispatches on the type
    # of the node and creates either a MultipleLHSExpression or a SingleLHSExpression
    module LHSExpression
      def self.new(node)
        case node[0]
        when Array, :mlhs_paren, :mlhs_add_star
          MultipleLHSExpression.new(node)
        else
          SingleLHSExpression.new(node)
        end
      end
    end
    # Represents a single variable on the LHS of an assignment.
    class SingleLHSExpression
      def initialize(lhs_node)
        @node = lhs_node
      end
      
      def contains_messages?
        @node.type == :aref_field || @node.type == :field
      end
      
      def size
        names.size
      end
      
      def names
        [@node.expanded_identifier]
      end
      
      def assignment_pairs(values)
        if Array === values && values.size == 1
          [[@node, values.first]]
        else
          [[@node, values]]
        end
      end
    end

    # Represents multiple variables on the LHS of an assignment.
    # A MultipleLHSExpression has several constituent LHSExpressions, either
    # Single or Multiple.
    class MultipleLHSExpression < SingleLHSExpression
      def initialize(lhs_node)
        @node = lhs_node
        @star = :unset
        extract_elements
      end
      
      # Extracts the top-level LHS nodes from the node this LHS expression
      # is based on.
      def extract_elements
        case @node[0]
        when Array
          @elements = wrap_as_lhs(@node)
        when :mlhs_paren
          @elements = [LHSExpression.new(@node[1])]
        when :mlhs_add_star
          if @node[2]
            @elements = [LHSExpression.new(@node[1]), LHSExpression.new(@node[2])]
          else
            @elements = [LHSExpression.new(@node[1])]
          end
          @elements << LHSExpression.new(@node[3]) if @node[3]
          @pre_star = wrap_as_lhs(@node[1])
          @post_star = @node[3] && wrap_as_lhs(@node[3]) || []
          @star = @elements[1]
        end
      end
      
      def wrap_as_lhs(list)
        list.map { |x| LHSExpression.new(x) }
      end
      
      def contains_messages?
        @elements.all?(&:contains_messages?)
      end
      
      def names
        @elements.map(&:names).flatten
      end
      
      def assignment_pairs(values)
        if values.size == 1 && values.first.respond_to?(:to_ary)
          values = values.first.to_ary
        end
        if @star == :unset
          if @elements.size == 1
            @elements.first.assignment_pairs(values)
          else
            result = @elements.zip(values).map do |elt, val|
              elt.assignment_pairs(val)
            end.inject(&:concat)
          end
        else
          # TODO(adgar): ERROR HANDLING
          pre_values = values[0, @pre_star.size]
          splat_count = [0, values.size - @pre_star.size - @post_star.size].max
          splat_values = values[@pre_star.size, splat_count]
          post_values = values[@pre_star.size + splat_count..-1] || []

          pre_pairs = @pre_star.zip(pre_values).map do |elt, val|
            elt.assignment_pairs(val)
          end.inject(&:concat) || []
          star_pair = @star ? @star.assignment_pairs(splat_values) : []
          post_pairs = @post_star.zip(post_values).map do |elt, val|
            elt.assignment_pairs(val)
          end.inject(&:concat) || []

          pre_pairs.concat(star_pair).concat(post_pairs)
        end
      end
    end
    
    # Entry point for creating RHS Expressions. RHS Expressions are used to
    # model the RHS of an expression. Unlike an LHS, we don't necessarily even
    # know the size of the RHS, because of constructions such as:
    # 
    #    a, b, c = 1, *impure_method_call()
    #
    # which make it impossible to know if c will be set to nil or not.
    module RHSExpression
      def self.new(node)
        case node[0]
        when Array, :mrhs_new_from_args, :args_add_star, :mrhs_add_star then MultipleRHSExpression.new(node)
        else SingleRHSExpression.new(node)
        end
      end
    end
    
    # This is a single node in an RHS expression. It contains exactly
    # one (potentially constant) value.
    class SingleRHSExpression
      def initialize(rhs_node)
        @node = rhs_node
      end
      
      def constant_size?
        true
      end
      
      def size
        constant_values.size
      end
      
      def is_constant
        @node.is_constant
      end
      
      def constant_values
        [@node.constant_value]
      end
    end
    
    # This is a splatted node in an RHS expression. Its size depends on
    # the size of its splatted argument, which may or may not be known at
    # compile-time. If it is constant, we can and will calculate both the
    # size and the values to be splatted.
    class StarRHSExpression < SingleRHSExpression      
      def constant_size?
        @node.is_constant
      end
      
      # Splatting calls Kernel::Array. Let's do that and wrap the result up in
      # proxies.
      def constant_values
        wrap_in_new_proxies(Array(@node.constant_value.raw_object))
      end
      
      private
      # Wraps the items in RealObjectProxies.
      def wrap_in_new_proxies(list)
        list.map do |item|
          RealObjectProxy.new(ClassRegistry[item.class.name], @node.scope,
             "#<#{item.class.name}:#{object_id.to_s(16)}>", item)
        end
      end
    end

    class MultipleRHSExpression < SingleRHSExpression
      attr_reader :elements
      def initialize(rhs_node)
        super
        extract_elements
      end
      
      # Returns whether the multiple-RHS has a constant size. This is true iff
      # there are no splats on variable-sized values in the RHS.
      def constant_size?
        @elements.all?(&:constant_size?)
      end
      
      # Returns the size of the RHS. This should only be called iff
      # constant_size? returns true.
      #
      # pre-contract: constant_size?.should be true
      def size
        @elements.map(&:size).inject(:+)
      end
      
      # Returns whether the RHS is composed entirely of constant values.
      def is_constant
        @elements.all?(&:is_constant)
      end
      
      # Returns all constant values in the RHS. Should only be called iff
      # is_constant is true.
      #
      # pre-contract: is_constant.should be true
      def constant_values
        wrap_in_new_proxies(Array(@elements.map(&:constant_values).inject(&:+).map(&:raw_object)))
      end
      
      private
      # Wraps up the items in RealObjectProxys.
      def wrap_in_new_proxies(list)
        list.map do |item|
          RealObjectProxy.new(ClassRegistry[item.class.name], @node.scope,
             "#<#{item.class.name}:#{object_id.to_s(16)}>", item)
        end
      end
      
      def extract_elements
        case @node[0]
        when Array
          @elements = wrap_as_rhs(@node)
        when :mrhs_new_from_args
          @elements = [RHSExpression.new(@node[1]), RHSExpression.new(@node[2])]
        when :args_add_star, :mrhs_add_star
          @elements = [RHSExpression.new(@node[1]), StarRHSExpression.new(@node[2]), *wrap_as_rhs(@node[3..-1])]
        end
      end
      
      # Wraps the list in RHSExpression nodes, creating a tree structure.
      def wrap_as_rhs(list)
        list.map { |x| RHSExpression.new(x) }
      end
    end

    # This class models an assignment, possibly a parallel or operator assignment,
    # in Ruby. Due to the complexities of parallel assignment and subexpressions,
    # this has to be in its own module of code.
    class AssignmentExpression
      attr_reader :lhs, :rhs

      def initialize(node)
        type = node.type
        lhs = node[1]
        case type
        when :assign, :massign then rhs = node[2]
        when :opassign then rhs = node[3]
        end

        @lhs = LHSExpression.new(lhs)
        @rhs = RHSExpression.new(rhs)
      end
      
      # This should only be run, at present, if the RHS is a constant. Later improvements
      # may allow partial assignment.
      #
      # pre-contract: @rhs.is_constant.should be true
      def assignment_pairs
        @lhs.assignment_pairs(@rhs.constant_values)
      end
      
      def is_constant
        !@lhs.contains_messages? && @rhs.is_constant
      end
    end
  end
end