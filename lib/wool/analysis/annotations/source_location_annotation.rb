module Wool
  module SexpAnalysis
    # This is a simple inherited attribute applied to each node,
    # giving a pointer to that node's next and previous AST node.
    # That way AST traversal is easier.
    module SourceLocationAnnotation
      extend BasicAnnotation
      add_properties :source_begin, :source_end
      
      # This is the annotator for the next and prev annotation.
      class Annotator
        include Visitor
        
        def default_visit(node)
          visit_children(node)
          if (first_child = node.children.find { |child| Sexp === child })
            node.source_begin = first_child.source_begin
          end
          if (last_child = node.children.reverse.find { |child| Sexp === child })
            node.source_end = last_child.source_end
          end
        end
        
        add :@ident, :@int, :@kw, :@float, :@tstring_content, :@regexp_end,
            :@ivar, :@cvar, :@gvar, :@const, :@label, :@CHAR do |node, text, location|
          node.source_begin = location
          node.source_end = location.dup
          node.source_end[1] += text.size
        end
        
        add :regexp_literal do |node, components, regexp_end|
          default_visit node
          node.source_begin = node.source_begin.dup  # make a copy we can mutate
          if text_at(node.source_begin, -1, 1) == '/'
            node.source_begin[1] -= 1
          end
        end
        
        def text_at(location, offset, length)
          line = lines[location[0] - 1]
          line[location[1] + offset, length]
        end
      end
      add_global_annotator Annotator
    end
  end
end