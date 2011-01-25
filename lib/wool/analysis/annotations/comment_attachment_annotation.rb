module Wool
  module SexpAnalysis
    # This is a simple inherited attribute applied to each node,
    # giving a pointer to that node's parent. That way AST traversal
    # is easier.
    module CommentAttachmentAnnotation
      extend BasicAnnotation
      add_property :docstring
      
      # This is the annotator for the parent annotation.
      class Annotator
        def annotate_with_text(root, text)
          comments = extract_comments(text)
          comments.each do |comment|
            
          end
        end
        
        def extract_comments(text)
          tokens = Ripper.lex(text).map { |tok| LexicalAnalysis::Token.new(tok) }
          comments = ObjectRegex.new('comment (sp? comment)*').all_matches(tokens).map do |token_list|
            token_list.select { |token| token.type == :on_comment }
          end.map do |token_list|
            body = token_list.map { |comment_token| comment_token.body[1..-1] }.join
            Comment.new(body, token_list.first.line, token_list.first.col)
          end
        end
      end
      add_global_annotator Annotator
    end
  end
end