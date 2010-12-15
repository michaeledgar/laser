module Wool
  # This is a set of methods that get provided to Warnings so they can perform
  # parse-tree analysis of their bodies.
  module SexpAnalysis
    extend ModuleExtensions
    
    # Replaces the ParseTree Sexps by adding a few handy-dandy methods.
    class Sexp < Array
      extend ModuleExtensions
      
      # Returns a mutable reference to the list of annotations that will run
      # upon initializing a new Sexp.
      #
      # @return [Array[Class < Annotation]] the activated annotations, in the
      #    order they will run in.
      cattr_accessor_with_default :annotations, []
      
      # Initializes the Sexp with the contents of the array returned by Ripper.
      #
      # @param [Array<Object>] other the other 
      def initialize(other)
        replace other
        replace_children!
        self.class.annotations.each {|annotator| annotator.annotate!(self) }
      end
      
      # @return [Array<Object>] the children of the node.
      def children
        (Array === self[0] ? self : self[1..-1]) || []
      end
      
      # @return [Symbol] the type of the node.
      def type
        self[0]
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
    
    # Parses the given text.
    #
    # @param [String] body (self.body) The text to parse
    # @return [Sexp, NilClass] the sexp representing the input text.
    def parse(body = self.body)
      result = Sexp.new Ripper.sexp(body)
      SexpAnalysis.global_annotations.each {|annotator| annotator.annotate!(result)}
      result
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