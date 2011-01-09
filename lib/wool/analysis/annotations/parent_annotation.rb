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
        def annotate!(root)
          root.parent = nil
          root.children.select {|x| SexpAnalysis::Sexp === x}.each do |sexp|
            sexp.parent = root
          end
        end
      end
      add_annotator Annotator
    end
  end
end