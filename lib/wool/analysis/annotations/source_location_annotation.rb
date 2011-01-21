module Wool
  module SexpAnalysis
    # This is a simple inherited attribute applied to each node,
    # giving a pointer to that node's next and previous AST node.
    # That way AST traversal is easier.
    module SourceLocationAnnotation
      extend BasicAnnotation
      add_properties :source_begin
      
      # This is the annotator for the next and prev annotation.
      class Annotator
        include Visitor
        
        def default_visit(node)
          visit_children(node)
          if (first_child = node.children.find { |child| Sexp === child })
            node.source_begin = first_child.source_begin
          end
        end
        
        add :@ident, :@int, :@kw, :@float, :@tstring_content, :@regexp_end,
            :@ivar, :@cvar, :@gvar, :@const, :@label, :@CHAR do |node, text, location|
          node.source_begin = location
        end
      end
      add_global_annotator Annotator
    end
  end
end