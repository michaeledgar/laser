module Wool
  # This is a set of methods that get provided to Warnings so they can perform
  # lexical analysis of their bodies. This module handles tokenizing only - not
  # parse-trees.
  module LexicalAnalysis
    def self.included(klass)
      klass.__send__(:extend, ClassMethods)
      klass.__send__(:include, InstanceMethods)
    end

    module ClassMethods
      extend Advice

      def lex(body)
        Ripper::Lexer.new(body).lex
      end

      def prelex(body, *args)
        body === Array ? [body, *args] : [lex(body), *args]
      end

      def find_keyword(body, keyword)
        body.find {|tok| tok[1] == :on_kw && tok[2] == keyword}
      end
      argument_advice :find_keyword, :prelex

      def find_token(body, token, text=nil)
        body.find {|tok| tok[1] == token}
      end
      argument_advice :find_token, :prelex
    end

    module InstanceMethods
      def lex(body = self.body)
        @lexed ||= self.class.lex(body)
      end

      def find_token(body = self.body, token)
        self.class.find_token(body, token)
      end

      def find_keyword(body = self.body, keyword)
        self.class.find_keyword(body, keyword)
      end
    end
  end
end