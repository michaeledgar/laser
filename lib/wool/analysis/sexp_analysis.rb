module Wool
  # This is a set of methods that get provided to Warnings so they can perform
  # parse-tree analysis of their bodies.
  module SexpAnalysis
    # Parses the given text.
    #
    # @param [String] body (self.body) The text to lex
    # @return [Array<Array<Integer, Integer>, Symbol, String>] A set of tokens
    #   in Ripper's result format. Each token is an array of the form:
    #   [[1, token_position], token_type, token_text]. I'm not exactly clear on
    #   why the 1 is always there. At any rate - the result is an array of those
    #   tokens.
    def parse(body = self.body)
      Ripper.sexp(body)
    end
    
    def find_sexps(type, tree = self.parse(self.body))
      result = tree[0] == type ? [tree] : []
      tree.each do |node|
        result.concat find_sexps(type, node) if node.is_a?(Array)
      end
      result
    end
  end
end