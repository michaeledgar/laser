module Laser
  module Analysis
    class MethodCall
      attr_reader :node
      
      def initialize(node)
        @node = node
      end

      def implicit_receiver?
        case node.type
        when :call, :aref, :unary, :binary, :super, :zsuper then false
        when :fcall, :command, :command_call, :var_ref, :vcall then true
        when :method_add_block, :method_add_arg then node[1].method_call.implicit_receiver?
        end
      end
      
      # Calculates the name of the method this method call represents.
      #
      # returns: String
      def method_name
        case node.type
        when :super, :zsuper then 'super'
        when :aref then :[]
        when :unary then node[1]
        when :binary then node[2]
        when :fcall, :command, :vcall then node[1].expanded_identifier.to_sym
        when :call, :command_call then node[3].expanded_identifier.to_sym
        when :var_ref then node.expanded_identifier.to_sym
        when :method_add_block, :method_add_arg then node[1].method_call.method_name
        end
      end

      # The receiver node is the node representing the explicit receiver.
      # If nil, then the implicit receiver, self, is used.
      #
      # return: Sexp | NilClass
      def receiver_node
        case node.type
        when :method_add_arg, :method_add_block then node[1].method_call.receiver_node
        when :var_ref, :vcall, :command, :fcall, :super, :zsuper, :unary then nil
        when :call, :command_call, :binary, :aref then node[1]        
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
        when :method_add_arg then (node[2][1] ? node[2][1] : nil)
        when :method_add_block then node[1].method_call.arg_node
        when :call, :var_ref, :vcall, :command_call, :zsuper then nil
        when :command_call then node[4][1]
        when :super
          node[1].type == :arg_paren ? node[1][1] : node[1]
        end
      end
    end
  end
end