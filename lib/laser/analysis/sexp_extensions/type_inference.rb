module Laser::SexpAnalysis
  module SexpExtensions
    module TypeInference
      # Finds the type of the AST node. This depends on the node's scope sometimes,
      # and always upon its node type.
      def expr_type
        case self.type
        when :string_literal, :@CHAR, :@tstring_content, :string_embexpr, :string_content,
             :xstring_literal
          Types::ClassType.new('String', :invariant)
        when :@int
          Types::ClassType.new('Integer', :covariant)
        when :@float
          Types::ClassType.new('Float', :invariant)
        when :regexp_literal
          @expr_type ||= Types::ClassType.new('Regexp', :invariant)
        when :hash, :bare_assoc_hash
          @expr_type ||= Types::ClassType.new('Hash', :invariant)
        when :symbol_literal, :dyna_symbol, :@label
          Types::ClassType.new('Symbol', :invariant)
        when :array
          Types::ClassType.new('Array', :invariant)
        when :dot2, :dot3 
          Types::ClassType.new('Range', :invariant)
        when :lambda 
          Types::ClassType.new('Proc', :invariant)
        when :var_ref
          ref = self[1]
          if ref.type == :@kw && ref.expanded_identifier != 'self'
            case ref[1]
            when 'nil' then Types::ClassType.new('NilClass', :invariant)
            when 'true' then Types::ClassType.new('TrueClass', :invariant)
            when 'false' then Types::ClassType.new('FalseClass', :invariant)
            when '__FILE__' then Types::ClassType.new('String', :invariant)
            when '__LINE__' then Types::ClassType.new('Fixnum', :invariant)
            when '__ENCODING__' then Types::ClassType.new('Encoding', :invariant)
            end
          else
            self.scope.lookup(expanded_identifier).expr_type rescue Types::TOP
          end
        else
          Types::TOP
        end
      end
    end
  end
end