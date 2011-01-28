module Laser
  module SexpAnalysis
    # This is a simple synthesized attribute that extracts the full name of
    # an identifier (either constant, gvar, ivar, local var, etc) from the
    # AST node representing it. Mainly, this is for constants, since they
    # have really, really annoying ASTs for expressions such as A::B::C.
    # However, if we annotate *all* identifiers with their name, then symbol
    # resolution will be really easy when we get there.
    class ExpandedIdentifierAnnotation < BasicAnnotation
      add_property :expanded_identifier
      
      def default_visit(node)
        node.expanded_identifier = nil
        visit_children(node)
      end
      
      add :@ident, :@const, :@gvar, :@cvar, :@ivar do |node, string, _|
        node.expanded_identifier = string
      end
      
      add :var_ref, :var_field, :top_const_ref, :const_ref, :top_const_field do |node, ref|
        visit ref
        node.expanded_identifier = ref.expanded_identifier
      end
      
      add :const_path_ref, :const_path_field do |node, lhs, rhs|
        visit lhs
        visit rhs
        node.expanded_identifier = "#{lhs.expanded_identifier}::#{rhs.expanded_identifier}"
      end
    end
  end
end