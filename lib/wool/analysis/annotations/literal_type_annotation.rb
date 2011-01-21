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
        
        add :string_literal, :@CHAR, :@tstring_content, :string_embexpr, :string_content,
            :xstring_literal do |node|
          node.class_estimate = ExactClassEstimate.new(ClassRegistry['String'])
          visit_children(node)
        end
        
        add :@int do |node|
          node.class_estimate = ExactClassEstimate.new(ClassRegistry['Fixnum'])
          visit_children(node)
        end
        
        add :@float do |node|
          node.class_estimate = ExactClassEstimate.new(ClassRegistry['Float'])
          visit_children(node)
        end
        
        add :regexp_literal do |node|
          node.class_estimate = ExactClassEstimate.new(ClassRegistry['Regexp'])
          visit_children(node)
        end
        
        add :hash, :bare_assoc_hash do |node|
          node.class_estimate = ExactClassEstimate.new(ClassRegistry['Hash'])
          visit_children(node)
        end
        
        add :symbol_literal, :dyna_symbol, :@label do |node|
          node.class_estimate = ExactClassEstimate.new(ClassRegistry['Symbol'])
          visit_children(node)
        end
        
        add :array do |node|
          node.class_estimate = ExactClassEstimate.new(ClassRegistry['Array'])
          visit_children(node)
        end
        
        add :var_ref do |node, ref|
          if ref.type == :@kw
            node.class_estimate =
                case ref[1]
                when 'nil' then ExactClassEstimate.new(ClassRegistry['NilClass'])
                when 'true' then ExactClassEstimate.new(ClassRegistry['TrueClass'])
                when 'false' then ExactClassEstimate.new(ClassRegistry['FalseClass'])
                when '__FILE__' then ExactClassEstimate.new(ClassRegistry['String'])
                when '__LINE__' then ExactClassEstimate.new(ClassRegistry['Fixnum'])
                when '__ENCODING__' then ExactClassEstimate.new(ClassRegistry['Encoding'])
                end
          end
          visit_children(node)
        end
        
        add :dot2, :dot3 do |node|
          node.class_estimate = ExactClassEstimate.new(ClassRegistry['Range'])
          visit_children(node)
        end
        
        add :lambda do |node|
          node.class_estimate = ExactClassEstimate.new(ClassRegistry['Proc'])
          visit_children(node)
        end
      end
      add_global_annotator Annotator
    end
  end
end