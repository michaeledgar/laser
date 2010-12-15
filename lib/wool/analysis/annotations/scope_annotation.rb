module Wool
  module SexpAnalysis
    # This is a *global* annotation, namely the one that determines the statically-known
    # scope for each node in the AST, at the time of that node's execution. For
    # example, every node should be able to say "hey scope, what's 'this' for this
    # statement?", and be able to return its type (*NOT* its class, they're different).
    module ScopeAnnotation
      extend BasicAnnotation
      add_property :scope
      
      # This is the annotator for the parent annotation.
      class Annotator
        include Visitor
        def annotate!(root)
          @current_scope = Scope::GlobalScope
          visit(root)
        end
        
        def visit_module
          
        end
      end
      add_global_annotator Annotator
    end
  end
end