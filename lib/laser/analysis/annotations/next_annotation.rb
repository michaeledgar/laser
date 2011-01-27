module Laser
  module SexpAnalysis
    # This is a simple inherited attribute applied to each node,
    # giving a pointer to that node's next and previous AST node.
    # That way AST traversal is easier.
    # This is the annotator for the next and prev annotation.
    class NextPrevAnnotation < BasicAnnotation
      add_property :next, :prev
      include Visitor
      def default_visit(node)
        children = node.children
        children.each_with_index do |elt, idx|
          # ignore non-sexps. Primitives can't be annotated, sadly.
          if SexpAnalysis::Sexp === elt
            elt.next = children[idx+1]
            elt.prev = children[idx-1] if idx >= 1
          end
        end
        visit_children(node)
      end
    end
  end
end