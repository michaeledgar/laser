module Laser
  # This is a set of methods that get provided to Warnings so they can perform
  # parse-tree analysis of their bodies.
  module SexpAnalysis
    extend ModuleExtensions
    
    # Replaces the ParseTree Sexps by adding a few handy-dandy methods.
    class Sexp < Array
      extend ModuleExtensions
      attr_accessor :errors, :binding

      # Initializes the Sexp with the contents of the array returned by Ripper.
      #
      # @param [Array<Object>] other the other 
      def initialize(other)
        @errors = []
        replace other
        replace_children!
      end
      
      # @return [Array<Object>] the children of the node.
      def children
        (Array === self[0] ? self : self[1..-1]) || []
      end
      
      # @return [Symbol] the type of the node.
      def type
        self[0]
      end

      # is the given object a sexp?
      #
      # @return Boolean
      def is_sexp?(sexp)
        SexpAnalysis::Sexp === sexp
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
            self.class.new(x)
          else x
          end
        end)
      end
      private :replace_children!
    end
    
    # inputs: Array<(String, String)>
    #   Array of (filename, body) tuples.
    def self.analyze_inputs(inputs)
      Annotations.annotate_inputs(inputs)
    end
    
    PARSING_CACHE = {}
    
    # Parses the given text.
    #
    # @param [String] body (self.body) The text to parse
    # @return [Sexp, NilClass] the sexp representing the input text.
    def parse(body = self.body)
      return PARSING_CACHE[body] if PARSING_CACHE[body]
      pairs = SexpAnalysis.analyze_inputs([['(stdin)', body]])
      PARSING_CACHE[body] = pairs[0][1]
    end
    
    # Finds all sexps of the given type in the given Sexp tree.
    #
    # @param [Symbol] type the type of sexp to search for
    # @param [Sexp] tree (self.parse(self.body)) The tree to search in. Leave
    #   blank to search the entire body.
    # @return [Array<Sexp>] all sexps in the input tree (or whole body) that
    #   are of the given type.
    def find_sexps(type, tree = self.parse(self.body))
      result = tree[0] == type ? [tree] : []
      tree.each do |node|
        result.concat find_sexps(type, node) if node.is_a?(Array)
      end
      result
    end
  end
end