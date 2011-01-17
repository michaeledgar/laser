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
        
        def default_visit(node)
          node.class_estimate = ClassEstimate.new
          visit_children(node)
        end
        
        add :string_literal do |node, *rest|
          node.class_estimate = ClassEstimate.new(ClassRegistry['String'], ClassRegistry['String'])
          visit_children(node)
        end
        
        add :@int do |node, *rest|
          node.class_estimate = ClassEstimate.new(ClassRegistry['Fixnum'], ClassRegistry['Fixnum'])
          visit_children(node)
        end
        
        add :@float do |node, *rest|
          node.class_estimate = ClassEstimate.new(ClassRegistry['Float'], ClassRegistry['Float'])
          visit_children(node)
        end
        
        add :regexp_literal do |node, *rest|
          node.class_estimate = ClassRegistry.new(ClassRegistry['Regexp'], ClassRegistry['Regexp'])
          visit_children(node)
        end
        
        add :hash do |node, *rest|
          node.class_estimate = ClassRegistry.new(ClassRegistry['Hash'], ClassRegistry['Hash'])
          visit_children(node)
        end
        
        add :hash do |node, *rest|
          node.class_estimate = ClassRegistry.new(ClassRegistry['Hash'], ClassRegistry['Hash'])
          visit_children(node)
        end
        
        add :symbol_literal do |node, *rest|
          node.class_estimate = ClassRegistry.new(ClassRegistry['Symbol'], ClassRegistry['Symbol'])
          visit_children(node)
        end
        
        add :dyna_symbol do |node, *rest|
          node.class_estimate = ClassRegistry.new(ClassRegistry['Symbol'], ClassRegistry['Symbol'])
          visit_children(node)
        end
        
        add :array do |node, *rest|
          node.class_estimate = ClassRegistry.new(ClassRegistry['Array'], ClassRegistry['Array'])
          visit_children(node)
        end
      end
      add_global_annotator Annotator
    end
  end
end