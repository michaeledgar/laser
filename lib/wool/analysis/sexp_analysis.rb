module Wool
  # This is a set of methods that get provided to Warnings so they can perform
  # parse-tree analysis of their bodies.
  module SexpAnalysis
    extend ModuleExtensions
    
    # Replaces the ParseTree Sexps by adding a few handy-dandy methods.
    class Sexp < Array
      extend ModuleExtensions

      # Initializes the Sexp with the contents of the array returned by Ripper.
      #
      # @param [Array<Object>] other the other 
      def initialize(other)
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
    
    # Global annotations are only run once, at the root. 
    cattr_accessor_with_default :global_annotations, []
    
    # inputs: Array<(String, String)>
    #   Array of (filename, body) tuples.
    def self.analyze_inputs(inputs)
      inputs.map! { |filename, text| [filename, Sexp.new(Ripper.sexp(text))] }
      SexpAnalysis.global_annotations.each do |annotator|
        inputs.each do |filename, tree|
          annotator.annotate!(tree)
        end
      end
      inputs
    end
    
    # Parses the given text.
    #
    # @param [String] body (self.body) The text to parse
    # @return [Sexp, NilClass] the sexp representing the input text.
    def parse(body = self.body)
      pairs = SexpAnalysis.analyze_inputs([['(stdin)', body]])
      pairs[0][1]
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