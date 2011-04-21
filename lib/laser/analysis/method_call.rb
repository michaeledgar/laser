module Laser
  module SexpAnalysis
    class MethodCall
      attr_reader :node
      
      def initialize(node)
        @node = node
      end

      IMPLICITS = [:fcall, :command, :command_call, :var_ref]
      def implicit_receiver?
        case node.type
        when :call, :aref, :unary, :binary, :super, :zsuper then false
        when :fcall, :command, :command_call, :var_ref then node[1].expanded_identifier
        when :method_add_block, :method_add_arg then node[1].method_call.implicit_receiver?
        end
      end
      
      # Calculates the name of the method this method call represents.
      #
      # returns: String
      def method_name
        case node.type
        when :super, :zsuper then 'super'
        when :aref then '[]'
        when :unary then node[1].to_s
        when :binary then node[2].to_s
        when :fcall, :command then node[1].expanded_identifier
        when :call, :command_call then node[3].expanded_identifier
        when :var_ref then node.expanded_identifier
        when :method_add_block, :method_add_arg then node[1].method_call.method_name
        end
      end

      # What is the receiver type (assuming this node is a method call)?
      # returns: Types::Base
      def receiver_type
        receiver = case node.type
                   when :unary then node[2]
                   when :fcall, :command, :var_ref, :zsuper, :super then node.scope.lookup('self')
                   when :binary, :call, :aref then node[1]
                   when :command_call then node.scope.lookup(node[1].expanded_identifier)
                   end
        receiver.expr_type
      end

      # The receiver node is the node representing the explicit receiver.
      # If nil, then the implicit receiver, self, is used.
      #
      # return: Sexp | NilClass
      def receiver_node
        case node.type
        when :method_add_arg, :method_add_block then node[1].method_call.receiver_node
        when :var_ref, :command, :fcall, :super, :zsuper, :unary then nil
        when :call, :command_call, :binary, :aref then node[1]        
        end
      end
      
      # Determines the arity of the method call.
      #
      # return: Arity
      def arity
        case node.type
        when :unary, :var_ref then Arity::EMPTY
        when :binary then Arity.new(1..1)
        when :fcall, :call then Arity::ANY
        when :command, :method_add_arg then ArgumentExpansion.new(node[2]).arity
        when :command_call then ArgumentExpansion.new(node[4]).arity
        when :super then ArgumentExpansion.new(node[1]).arity
        when :zsuper then node.scope.method.arity
        end
      end
      
      # Returns an ArgumentExpansion representation of the arguments of this
      # method call.
      def arguments
        ArgumentExpansion.new(arg_node)
      end
      
      # Returns a node, if any, representing the arguments to this method call.
      #
      # returns: Sexp
      def arg_node
        case node.type
        when :command, :aref then node[2][1]
        when :method_add_arg then (node[2][1] ? node[2][1][1] : nil)
        when :method_add_block then node[1].method_call.arg_node
        when :call, :var_ref, :command_call, :zsuper then args = nil
        when :command_call then node[4][1]
        when :super then node[1]
        end
      end
    end
  end
end