module Laser
  module SexpAnalysis
    # Replaces the ParseTree Sexps by adding a few handy-dandy methods.
    class Sexp < Array
      include SexpExtensions::ConstantExtraction      
      include SexpExtensions::MethodResolution
      include SexpExtensions::SourceLocation
      include SexpExtensions::TypeInference
      
      extend ModuleExtensions
      attr_accessor :errors, :binding, :file_name, :file_source
      attr_accessor :reachable

      # Initializes the Sexp with the contents of the array returned by Ripper.
      #
      # @param [Array<Object>] other the other 
      def initialize(other, file_name=nil, file_source=nil)
        @reachable = true
        @expr_type = nil
        @errors = []
        @file_name = file_name
        @file_source = file_source
        replace other
        replace_children!
      end
  
      # @return [Array<Object>] the children of the node.
      def children
        @children ||= ((Array === self[0] ? self : self[1..-1]) || [])
      end
  
      # @return [Symbol] the type of the node.
      def type
        self[0]
      end

      def add_error(error)
        errors << error unless errors.include?(error)
      end

      # is the given object a sexp?
      #
      # @return Boolean
      def is_sexp?(sexp)
        SexpAnalysis::Sexp === sexp
      end

      def lines
        @file_source.lines.to_a
      end

      def find_type(type)
        deep_find { |node| node.type == type }
      end

      # Same as #find for Enumerable, only recursively. Useful for "jumping"
      # past useless parser nodes.
      def deep_find
        ([self] + all_subtrees.to_a).each do |node|
          return node if yield(node)
        end
      end
  
      def all_subtrees
        to_visit = self.children.dup
        visited = Set.new
        while to_visit.any?
          todo = to_visit.shift
          next unless is_sexp?(todo)

          case todo[0]
          when Array
            to_visit.concat todo
          when ::Symbol
            to_visit.concat todo.children
            visited << todo
          end
        end
        visited
      end
  
      # Returns an enumerator that iterates over each subnode of this node
      # in DFS order.
      def dfs_enumerator
        Enumerator.new do |g|
          dfs do |node|
            g.yield node
          end
        end
      end
  
      # Returns all errors in this subtree, in DFS order.
      # returns: [Error]
      def all_errors
        dfs_enumerator.map(&:errors).flatten
      end
  
      # Performs a DFS on the node, yielding each subnode (including the given node)
      # in DFS order.
      def dfs
        yield self
        self.children.each do |child|
          next unless is_sexp?(child)
          case child[0]
          when Array
            child.each { |x| x.dfs { |y| yield y}}
          when ::Symbol
            child.dfs { |y| yield y }
          end
        end
      end
  
      # Replaces the children with Sexp versions of them
      def replace_children!
        replace(map do |x|
          case x
          when Array
            self.class.new(x, @file_name, @file_source)
          else x
          end
        end)
      end
      private :replace_children!
      
      # Returns the text of the identifier, assuming this node identifies something.
      def expanded_identifier
        case type
        when :@ident, :@const, :@gvar, :@cvar, :@ivar, :@kw, :@op
          self[1]
        when :var_ref, :var_field, :const_ref, :symbol
          self[1].expanded_identifier
        when :top_const_ref, :top_const_field
          "::#{self[1].expanded_identifier}"
        when :const_path_ref, :const_path_field
          lhs, rhs = children
          "#{lhs.expanded_identifier}::#{rhs.expanded_identifier}"
        end
      end
      
      def is_method_call?
        [:command, :method_add_arg, :method_add_block, :var_ref, :call,
         :fcall, :command_call, :binary, :unary, :super, :zsuper, :aref].include?(type) &&
            !(type == :var_ref && (binding || self[1].type == :@kw))
      end
      
      # Returns the MethodCall wrapping up all the method call information about this
      # node.
      #
      # raises: TypeError
      # return: MethodCall
      def method_call
        unless is_method_call?
          raise TypeError.new("Only method call nodes define #method_call. "+
                              "This node is of type #{type}.")
        end
        MethodCall.new(self)
      end
    end
  end
end