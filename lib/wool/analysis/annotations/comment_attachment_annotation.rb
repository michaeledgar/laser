module Wool
  module SexpAnalysis
    # This is a simple inherited attribute applied to each node,
    # giving a pointer to that node's parent. That way AST traversal
    # is easier.
    module CommentAttachmentAnnotation
      extend BasicAnnotation
      add_property :docstring
      
      Comment = Struct.new(:body, :location) do
        
      end
      
      # This is the annotator for the parent annotation.
      class Annotator
        def annotate_with_text(root, text)
          comments = extract_comments(text)
          # do something with comments.
        end
        
        def extract_comments(text)
          tokens = Ripper.lex(text).map { |tok| LexicalAnalysis::Token.new(tok) }
          ObjectRegex.new('comment (sp? comment)*').all_matches(tokens)
        end
      end
      add_global_annotator Annotator
    end
  end
end