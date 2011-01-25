module Wool
  module SexpAnalysis
    # This is a simple inherited attribute applied to each node,
    # giving a pointer to that node's parent. That way AST traversal
    # is easier.
    module CommentAttachmentAnnotation
      extend BasicAnnotation
      add_property :comment
      
      # This is the annotator for the parent annotation.
      class Annotator
        def annotate_with_text(root, text)
          comments = extract_comments(text)
          # root[1] here to ignore the spurious :program node
          dfs_enumerator = root.dfs_enumerator
          # For each comment:
          #   find the first node, by DFS, that has a location *greater* than the
          #   comment's. However, not all nodes will have locations due to Ripper
          #   being kinda crappy.
          # When the enumerator finishes (raises StopIteration): we can no longer
          #   annotate. So return.
          comments.each do |comment|
            begin
              cur = dfs_for_useful_node(dfs_enumerator)
            end while (cur.source_begin <=> comment.location) == -1
            # if we're here, we found the first node after the comment.
            cur.comment = comment
            extend_annotation_to_equal_nodes(cur, dfs_enumerator)
          end
        rescue StopIteration
          # do nothing – this signals the end of the algorithm. If has_next made sense
          # for enumerators, we'd use it, but it doesn't, so we just catch and return.
        end
        
        # Runs the generator until we find a node we can use in the context of
        # comment annotation: it must have a source_begin attribute (not all nodes
        # can successfully resolve their source_begin) and it shouldn't be a mere
        # Array, it should have an actual node type.
        def dfs_for_useful_node(generator)
          begin
            cur = generator.next
          end until cur.source_begin && (::Symbol === cur[0])
          cur
        end
        
        # Many nodes in the tree will have the same source_begin value, and they
        # must all share the comment. Otherwise, we'll have a lot of trouble making
        # sure that the interesting nodes, often nested deeply, will be annotated.
        def extend_annotation_to_equal_nodes(first, generator)
          while generator.peek.source_begin == first.source_begin
            generator.next.comment = first.comment
          end
        end
        
        # Extracts the comments from the text with some straightforward lexical analysis.
        def extract_comments(text)
          tokens = Ripper.lex(text).map { |tok| LexicalAnalysis::Token.new(tok) }
          comments = ObjectRegex.new('comment (sp? comment)*').all_matches(tokens).map do |token_list|
            token_list.select { |token| token.type == :on_comment }
          end.map do |token_list|
            body = token_list.map { |comment_token| comment_token.body[1..-1] }.join.rstrip
            Comment.new(body, token_list.first.line, token_list.first.col)
          end
        end
      end
      add_global_annotator Annotator
    end
  end
end