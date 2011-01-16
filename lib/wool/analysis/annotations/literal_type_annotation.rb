module Wool
  module SexpAnalysis
    # This is a simple inherited attribute applied to each node,
    # giving a pointer to that node's next and previous AST node.
    # That way AST traversal is easier.
    module LiteralTypeAnnotation
      extend BasicAnnotation
      add_properties :class_estimate
      
      # This is the annotator for the next and prev annotation.
      class Annotator
        include Visitor
        def annotate!(root)
          visit root
        end
        
        
      end
      add_global_annotator Annotator
    end
  end
end