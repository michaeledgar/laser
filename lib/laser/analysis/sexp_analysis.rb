module Laser
  # This is a set of methods that get provided to Warnings so they can perform
  # parse-tree analysis of their bodies.
  module SexpAnalysis
    extend ModuleExtensions
        
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