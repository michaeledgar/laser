module Wool
  module SexpAnalysis
    # This is a simple inherited attribute applied to each node,
    # giving a pointer to that node's parent. That way AST traversal
    # is easier.
    module ParentAnnotation
      extend BasicAnnotation
      add_property :parent
      
      # This is the annotator for the parent annotation.
      class Annotator
        def annotate!(root)
          root.parent = nil
          root.children.select {|x| SexpAnalysis::Sexp === x}.each {|sexp| sexp.parent = root}
        end
      end
      add_annotator Annotator
    end
  end
end