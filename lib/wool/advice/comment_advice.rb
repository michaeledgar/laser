module Wool
  module Advice
    # Using this module, you can make your match? method automatically
    # receive de-commented source text.
    #
    # class MyWarning < Wool::Warning do
    #   extend Wool::Advice::CommentAdvice
    #
    #   def self.match?(body, describe)
    #     body.include?('#')
    #   end
    #   remove_comments
    # end
    module CommentAdvice
      def self.included(klass)
        klass.__send__(:extend, ClassMethods)
        klass.__send__(:include, InstanceMethods)
      end

      module ClassMethods
        def remove_comments
          argument_advice :match?, :comment_removing_twiddler
        end
      end

      module InstanceMethods
        # This twiddler aims to remove comments and trailing whitespace
        # from the ruby source input, so that warnings that aren't concerned
        # with the implications of comments in their source can safely
        # discard them. Uses Ripper to look for comment tokens.
        def comment_removing_twiddler(body = self.body, settings = {})
          [split_on_token(body, :on_comment).first.rstrip, settings]
        end
      end
    end
  end
end