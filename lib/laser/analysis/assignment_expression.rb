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
      
      def names
        [@node.expanded_identifier]
      end
    end

    # Represents multiple variables on the LHS of an assignment.
    # A MultipleLHSExpression has several constituent LHSExpressions, either
    # Single or Multiple.
    class MultipleLHSExpression
      def initialize(lhs_node)
        @node = lhs_node
        @star = nil
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
          @elements = wrap_as_lhs(@node[1])
          @star = LHSExpression.new(@node[2])
          @elements << @star
          @elements.concat(wrap_as_lhs(@node[3])) if @node[3]
        end
      end
      
      def wrap_as_lhs(list)
        list.map { |x| LHSExpression.new(x) }
      end
      
      def names
        @elements.map(&:names).flatten
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
    
    # This is a single node in an RHS expression. 
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
    
    class StarRHSExpression < SingleRHSExpression      
      def constant_size?
        @node.is_constant
      end
      
      def constant_values
        wrap_in_new_proxies(Array(@node.constant_value.raw_object))
      end
      
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
      
      def constant_size?
        @elements.all?(&:constant_size?)
      end
      
      def size
        @elements.map(&:size).inject(:+)
      end
      
      def is_constant
        @elements.all?(&:is_constant)
      end
      
      def constant_values
        wrap_in_new_proxies(Array(@elements.map(&:constant_values).inject(&:+).map(&:raw_object)))
      end
      
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
      
      def wrap_as_rhs(list)
        list.map { |x| RHSExpression.new(x) }
      end
    end

    # This class models an assignment, possibly a parallel or operator assignment,
    # in Ruby. Due to the complexities of parallel assignment and subexpressions,
    # this has to be in its own module of code.
    class AssignmentExpression
      attr_reader :lhs, :rhs
      def initialize(assignment_node)
        type = assignment_node.type
        lhs = assignment_node[1]
        case type
        when :assign, :massign then rhs = assignment_node[2]
        when :opassign then rhs = assignment_node[3]
        end

        @lhs = LHSExpression.new(lhs)
        @rhs = RHSExpression.new(rhs)
      end
    end
  end
end