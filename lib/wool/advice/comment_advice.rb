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
          "hello \\#"
          def comment_removing_twiddler(body, context)
            in_string = was_slash = false
            1.upto(body.size) do |len|
              char = body[len-1,1]
              if char == '#' && !in_string
                return [body[0,len-1].rstrip, context]
              end
              if (char == '"' || char == "'") && !in_string
                in_string = true
              elsif (char == '"' || char == "'") && !was_slash
                in_string = false
              end
              was_slash = char == '\\'
            end
            [body, context]
          end
          argument_advice :match?, :comment_removing_twiddler
        end
      end
    end
  end
end