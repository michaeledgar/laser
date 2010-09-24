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
      Ripper.lex(body)
    end

    # Finds the first instance of a set of keywords in the body. If no text is
    # given to scan, then the full content is scanned.
    #
    # @param [String] body (self.body) The first parameter is optional: the text
    #   to search. This defaults to the full text.
    # @param [Symbol] keyword The rest of the arguments are keywords to search
    #   for. Any number of keywords may be specified.
    # @return [Array] the token in the form returned by Ripper. See #lex.
    def find_keyword(*args)
      body, list = _extract_token_search_args(args)
      list.map! {|x| x.to_s}
      lex(body).find {|tok| tok[1] == :on_kw && list.include?(tok[2])}
    end

    # Finds the first instance of a set of tokens in the body. If no text is
    # given to scan, then the full content is scanned.
    #
    # @param [String] body (self.body) The first parameter is optional: the text
    #   to search. This defaults to the full text.
    # @param [Symbol] token The rest of the arguments are tokens to search
    #   for. Any number of tokens may be specified.
    # @return [Array] the token in the form returned by Ripper. See #lex.
    def find_token(*args)
      body, list = _extract_token_search_args(args)
      lex(body).find {|tok| list.include?(tok[1])}
    end

    # Splits the body into two halfs based on the first appearance of a keyword.
    #
    # @example
    #   split_on_keyword('x = 5 unless y == 2', :unless)
    #   # => ['x = 5 ', 'unless y == 2']
    # @param [String] body (self.body) The first parameter is optional: the text
    #   to search. This defaults to the full text.
    # @param [Symbol] token The rest of the arguments are keywords to search
    #   for. Any number of keywords may be specified.
    # @return [Array<String, String>] The body split by the keyword.
    def split_on_keyword(*args)
      body, keywords = _extract_token_search_args(args)
      token = find_keyword(body, *keywords)
      return _split_body_with_raw_token(body, token)
    end

    # Splits the body into two halfs based on the first appearance of a token.
    #
    # @example
    #   split_on_token('x = 5 unless y == 2', :on_kw)
    #   # => ['x = 5 ', 'unless y == 2']
    # @param [String] body (self.body) The first parameter is optional: the text
    #   to search. This defaults to the full text.
    # @param [Symbol] token The rest of the arguments are tokens to search
    #   for. Any number of tokens may be specified.
    # @return [Array<String, String>] The body split by the token.
    def split_on_token(*args)
      body, tokens = _extract_token_search_args(args)
      token = find_token(body, *tokens)
      return _split_body_with_raw_token(body, token)
    end

    private

    def _extract_token_search_args(args)
      if args.first.is_a?(String)
        return args[0], args[1..-1]
      else
        return self.body, args
      end
    end

    def _split_body_with_raw_token(body, token)
      max = token ? [0, token[0][1]].max : body.size
      return body[0,max], body[max..-1]
    end
  end
end