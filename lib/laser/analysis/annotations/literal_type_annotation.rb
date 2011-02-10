module Laser
  module SexpAnalysis
    # This is a simple synthesized attribute applied to the common literals
    # and/or keywords to specify what classes those expressions will be.
    # This is the annotator for the next and prev annotation.
    class LiteralTypeAnnotation < BasicAnnotation
      add_property :expr_type
      
      def default_visit(node)
        node.expr_type = Types::TOP
        visit_children(node)
      end

      add :string_literal, :@CHAR, :@tstring_content, :string_embexpr, :string_content,
          :xstring_literal do |node|
        node.expr_type = Types::ClassType.new('String', :invariant)
        visit_children(node)
      end

      add :@int do |node|
        node.expr_type = Types::ClassType.new('Integer', :covariant)
        visit_children(node)
      end

      add :@float do |node|
        node.expr_type = Types::ClassType.new('Float', :invariant)
        visit_children(node)
      end
      
      add :regexp_literal do |node|
        node.expr_type = Types::ClassType.new('Regexp', :invariant)
        visit_children(node)
      end
      
      add :hash, :bare_assoc_hash do |node|
        node.expr_type = Types::ClassType.new('Hash', :invariant)
        visit_children(node)
      end
      
      add :symbol_literal, :dyna_symbol, :@label do |node|
        node.expr_type = Types::ClassType.new('Symbol', :invariant)
        visit_children(node)
      end
      
      add :array do |node|
        node.expr_type = Types::ClassType.new('Array', :invariant)
        visit_children(node)
      end
      
      add :var_ref do |node, ref|
        if ref.type == :@kw
          node.expr_type =
              case ref[1]
              when 'nil' then Types::ClassType.new('NilClass', :invariant)
              when 'true' then Types::ClassType.new('TrueClass', :invariant)
              when 'false' then Types::ClassType.new('FalseClass', :invariant)
              when '__FILE__' then Types::ClassType.new('String', :invariant)
              when '__LINE__' then Types::ClassType.new('Fixnum', :invariant)
              when '__ENCODING__' then Types::ClassType.new('Encoding', :invariant)
              end
        else
          default_visit node
        end
        visit_children(node)
      end
      
      add :dot2, :dot3 do |node|
        node.expr_type = Types::ClassType.new('Range', :invariant)
        visit_children(node)
      end
      
      add :lambda do |node|
        node.expr_type = Types::ClassType.new('Proc', :invariant)
        visit_children(node)
      end
    end
  end
end