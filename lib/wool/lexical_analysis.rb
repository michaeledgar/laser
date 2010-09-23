module Wool
  # This is a set of methods that get provided to Warnings so they can perform
  # lexical analysis of their bodies. This module handles tokenizing only - not
  # parse-trees.
  module LexicalAnalysis
    extend Advice

    # Lexes the given text.
    #
    # @param [String] body (self.body) The text to lex
    # @return [Array<Array<Integer, Integer>, Symbol, String>] A set of tokens
    #   in Ripper's result format. Each token is an array of the form:
    #   [[1, token_position], token_type, token_text]. I'm not exactly clear on
    #   why the 1 is always there. At any rate - the result is an array of those
    #   tokens.
    def lex(body = self.body)
      Ripper::Lexer.new(body).lex
    end

    # Finds the first instance of a set of keywords in the body. If no text is
    # given to scan, then the full content is scanned.
    #
    # @param [String] body (self.body) The first parameter is optional: the text
    #   to search. This defaults to the full text.
    # @param [String] keyword The rest of the arguments are keywords to search
    #   for. Any number of keywords may be specified.
    # @return [Array] the token in the form returned by Ripper. See #lex.
    def find_keyword(*args)
      if args.first.is_a?(String) && args.size > 1
        body, list = args[0], args[1..-1]
      else
        body, list = self.body, args
      end
      lex(body).find {|tok| tok[1] == :on_kw && list.include?(tok[2])}
    end

    # Finds the first instance of a set of tokens in the body. If no text is
    # given to scan, then the full content is scanned.
    #
    # @param [String] body (self.body) The first parameter is optional: the text
    #   to search. This defaults to the full text.
    # @param [String] token The rest of the arguments are tokens to search
    #   for. Any number of tokens may be specified.
    # @return [Array] the token in the form returned by Ripper. See #lex.
    def find_token(*args)
      if args.first.is_a?(String)
        body, list = args[0], args[1..-1]
      else
        body, list = self.body, args
      end
      lex(body).find {|tok| list.include?(tok[1])}
    end
  end
end