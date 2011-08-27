module Laser::Analysis
  module SexpExtensions
    module TypeInference
      # Finds the type of the AST node. This depends on the node's scope sometimes,
      # and always upon its node type.
      def expr_type
        case self.type
        when :string_literal, :@CHAR, :@tstring_content, :string_embexpr, :string_content,
             :xstring_literal
          Types::ClassObjectType.new('String')
        when :@int
          Types::ClassType.new('Integer', :covariant)
        when :@float
          Types::ClassObjectType.new('Float')
        when :regexp_literal
          @expr_type ||= Types::ClassObjectType.new('Regexp')
        when :hash, :bare_assoc_hash
          @expr_type ||= Types::ClassObjectType.new('Hash')
        when :symbol_literal, :dyna_symbol, :@label
          Types::ClassObjectType.new('Symbol')
        when :array
          Types::ClassObjectType.new('Array')
        when :dot2, :dot3 
          Types::ClassObjectType.new('Range')
        when :lambda 
          Types::ClassObjectType.new('Proc')
        when :var_ref
          ref = self[1]
          if ref.type == :@kw && ref.expanded_identifier != 'self'
            case ref[1]
            when 'nil' then Types::ClassObjectType.new('NilClass')
            when 'true' then Types::ClassObjectType.new('TrueClass')
            when 'false' then Types::ClassObjectType.new('FalseClass')
            when '__FILE__' then Types::ClassObjectType.new('String')
            when '__LINE__' then Types::ClassObjectType.new('Fixnum')
            when '__ENCODING__' then Types::ClassObjectType.new('Encoding')
            end
          else
            self.scope.lookup(expanded_identifier).expr_type rescue Types::TOP
          end
        else
          Laser::Types::TOP
        end
      end
    end
  end
end
