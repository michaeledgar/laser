module Wool
  module SexpAnalysis
    # This is a simple inherited attribute applied to each node,
    # giving a pointer to that node's parent. That way AST traversal
    # is easier.
    module ParentAnnotation
      extend BasicAnnotation
      add_property :parent
      add_computed_property :ancestors do
        case parent
        when nil then []
        else parent.ancestors + [parent]
        end
      end
      
      # This is the annotator for the parent annotation.
      class Annotator
        include Visitor
        # Replaces the general node visit method with one that assigns
        # the current scope to the visited node.
        def default_visit(node)
          node.children.select { |x| SexpAnalysis::Sexp === x }.each do |sexp|
            sexp.parent = node
          end
          visit_children(node)
        end
      end
      add_global_annotator Annotator
    end
  end
end