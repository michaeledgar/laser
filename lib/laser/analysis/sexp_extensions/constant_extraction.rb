module Laser::Analysis
  module SexpExtensions
    module ConstantExtraction
      
      # Is this node of constant value? This might be known statically (because
      # it is a literal) or it might be because it's been proven through analysis.
      def is_constant
        case self.type
        when :@CHAR, :@tstring_content, :@int, :@float, :@regexp_end, :symbol, :@label
          true
        when :string_content, :string_literal, :assoc_new, :symbol_literal, :dot2, :dot3
          children.all?(&:is_constant)
        when :hash
          self[1].nil? || self[1].is_constant
        when :array, :regexp_literal, :assoclist_from_args, :bare_assoc_hash, :dyna_symbol
          self[1].nil? || self[1].all?(&:is_constant)
        when :var_ref, :const_ref, :const_path_ref, :var_field
          if self[1].type == :@kw
            %w(nil true false self __LINE__ __FILE__).include?(expanded_identifier)
          elsif !self.binding.nil?
            Bindings::ConstantBinding === scope.lookup(expanded_identifier)
          end
        when :paren
          self[1].type != :params && self[1].all?(&:is_constant)
        else
          false
        end
      end
      
      # What is this node's constant value? This might be known statically (because
      # it is a literal) or it might be because it's been proven through analysis.
      def constant_value
        unless is_constant
          return :none
        end
        case type
        when :@CHAR
          char_part = self[1][1..-1]
          if char_part.size == 1
            char_part
          else
            eval(%Q{"#{char_part}"})
          end
        when :@tstring_content
          str = self[1]
          pos = self.parent.parent.source_begin
          first_two = lines[pos[0]-1][pos[1],2]
          if first_two[0,1] == '"' || first_two == '%Q'
            eval(%Q{"#{str}"})
          else   
            str
          end
        when :string_content
          children.map(&:constant_value).join
        when :string_literal, :symbol_literal
          self[1].constant_value
        when :@int
          Integer(self[1])
        when :@float
          Float(self[1])
        when :@regexp_end
          str = self[1]
          result = 0
          result |= Regexp::IGNORECASE if str.include?('i')
          result |= Regexp::MULTILINE  if str.include?('m')
          result |= Regexp::EXTENDED   if str.include?('x')
          result
        when :regexp_literal
          parts, options = children
          Regexp.new(parts.map(&:constant_value).join, options.constant_value)
        when :assoc_new
          children.map(&:constant_value)
        when :assoclist_from_args, :bare_assoc_hash
          parts = self[1]
          Hash[*parts.map(&:constant_value).flatten]
        when :hash
          part = self[1]
          part.nil? ? {} : part.constant_value
        when :symbol
          self[1][1].to_sym
        when :dyna_symbol
          parts = self[1]
          parts.map(&:constant_value).join.to_sym
        when :@label
          self[1][0..-2].to_sym
        when :array
          parts = self[1]
          parts.nil? ? [] : parts.map(&:constant_value)
        when :var_ref, :const_path_ref, :const_ref, :var_field
          case self[1].type
          when :@kw
            case self[1][1]
            when 'self' then scope.self_ptr
            when 'nil' then nil
            when 'true' then true
            when 'false' then false
            when '__LINE__' then self[1][2][0]
            when '__FILE__' then @file_name
            end
          else
            scope.lookup(expanded_identifier).value
          end
        when :dot2
          lhs, rhs = children
          (lhs.constant_value)..(rhs.constant_value)
        when :dot3
          lhs, rhs = children
          (lhs.constant_value)...(rhs.constant_value)
        when :paren
          self[1].last.constant_value
        end
      end
    end
  end
end
