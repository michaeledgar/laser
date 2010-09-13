module Wool
  module Advice
    # Using this module, you can make your match? method automatically
    # receive de-commented source text.
    #
    # class MyWarning < Wool::Warning do
    #   extend Wool::Advice::CommentAdvice
    #
    #   def self.match?(body, context)
    #     body.include?('#')
    #   end
    #   remove_comments
    # end
    module CommentAdvice
      def remove_comments
        class << self
          extend Advice
          # This twiddler aims to remove comments and trailing whitespace
          # from the ruby source input, so that warnings that aren't concerned
          # with the implications of comments in their source can safely
          # discard them. This is a bit more complicated than simply
          # gsub(/#.*$/,''), because there are strings with # in them too.
          #
          # Like all twiddlers, is conservative. It might get tripped up by
          # a comment embedded code in a string.
          def comment_removing_twiddler(body, context, settings = {})
            in_string = was_slash = false
            1.upto(body.size) do |len|
              char = body[len - 1,1]
              if char == '#' && !in_string
                return [body[0, len - 1].rstrip, context]
              end
              if (char == '"' || char == "'") && !in_string
                in_string = true
              elsif (char == '"' || char == "'") && !was_slash
                in_string = false
              end
              was_slash = char == '\\'
            end
            [body, context, settings]
          end
          argument_advice :match?, :comment_removing_twiddler
        end
      end
    end
  end
end