module Wool
  # This is a set of methods that get provided to Warnings so they can perform
  # lexical analysis of their bodies. This module handles tokenizing only - not
  # parse-trees.
  module LexicalAnalysis
    extend Advice

    def lex(body = self.body)
      Ripper::Lexer.new(body).lex
    end

    def find_keyword(body = self.body, keyword)
      lex(body).find {|tok| tok[1] == :on_kw && tok[2] == keyword}
    end

    def find_token(body = self.body, token)
      lex(body).find {|tok| tok[1] == token}
    end
  end
end