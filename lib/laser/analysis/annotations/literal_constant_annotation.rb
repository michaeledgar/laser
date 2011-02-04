module Laser
  module SexpAnalysis
    # This is a simple synthesized attribute applied to the common literals
    # and/or keywords to specify what their actual constant value is.
    class LiteralConstantAnnotation < BasicAnnotation
      add_property :is_constant
      add_property :constant_value
      
      def default_visit(node)
        node.is_constant = false
        node.constant_value = :none
        visit_children(node)
      end
      
      def wrap(node, klass, name="#<#{klass.path}:#{object_id.to_s(16)}>", val)
        node.constant_value = RealObjectProxy.new(klass, nil, name, val)
      end
      
      # TODO(adgar): Find a way to avoid eval?
      add :@CHAR do |node, char, location|
        node.is_constant = true
        # Microoptimization because i can
        char_part = char[1..-1]
        if char_part.size == 1
          wrap(node, ClassRegistry['String'], char_part)
        else
          wrap(node, ClassRegistry['String'], eval(%Q{"#{char_part}"}))
        end
      end
      
      add :@tstring_content do |node, str, location|
        node.is_constant = true
        pos = node.parent.parent.source_begin
        first_two = lines[pos[0]-1][pos[1],2]
        if first_two[0,1] == '"' || first_two == '%Q'
          wrap(node, ClassRegistry['String'], eval(%Q{"#{str}"}))
        else
          wrap(node, ClassRegistry['String'], str)
        end
      end
      
      add :string_content do |node|
        parts = node.children
        parts.each { |part| visit part }
        if (node.is_constant = parts.all?(&:is_constant))
          wrap(node, ClassRegistry['String'], parts.map(&:constant_value).map(&:raw_object).join)
        end
      end
      
      # TODO(adgar): string_embexpr
      add :string_literal do |node, content|
        visit content
        node.is_constant = content.is_constant
        node.constant_value = content.constant_value
      end
      
      add :@int do |node, repr, location|
        node.is_constant = true
        wrap(node, ClassRegistry['Integer'], Integer(repr))
      end
      
      add :@float do |node, repr, location|
        node.is_constant = true
        wrap(node, ClassRegistry['Float'], Float(repr))
      end
      
      add :@regexp_end do |node, str, location|
        result = 0
        result |= Regexp::IGNORECASE if str.include?('i')
        result |= Regexp::MULTILINE  if str.include?('m')
        result |= Regexp::EXTENDED   if str.include?('x')
        node.is_constant = true
        node.constant_value = result
      end
      
      add :regexp_literal do |node, parts, options|
        visit parts
        visit options
        options = options.constant_value
        if (node.is_constant = parts.all?(&:is_constant))
          wrap(node, ClassRegistry['Regexp'], Regexp.new(parts.map(&:constant_value).map(&:raw_object).join, options))
        end
      end
      
      add :assoc_new do |node, lhs, rhs|
        visit lhs
        visit rhs
        if (node.is_constant = lhs.is_constant && rhs.is_constant)
          node.constant_value = [lhs.constant_value, rhs.constant_value]
        end
      end
      
      add :assoclist_from_args, :bare_assoc_hash do |node, parts|
        visit parts
        if (node.is_constant = parts.all?(&:is_constant))
          wrap(node, ClassRegistry['Hash'], Hash[*parts.map(&:constant_value).flatten.map(&:raw_object)])
        end
      end
      
      add :hash do |node, part|
        visit part
        if part.nil?
          node.is_constant = true
          wrap(node, ClassRegistry['Hash'], {})
        else
          node.is_constant = part.is_constant
          node.constant_value = part.constant_value
        end
      end
      
      add :symbol do |node, ident|
        node.is_constant = true
        wrap(node, ClassRegistry['Symbol'], ident[1].to_sym)
      end
      
      add :symbol_literal do |node, sym|
        visit sym
        node.is_constant = sym.is_constant
        node.constant_value = sym.constant_value
      end
      
      add :dyna_symbol do |node, parts|
        parts.each { |part| visit part }
        if (node.is_constant = parts.all?(&:is_constant))
          wrap(node, ClassRegistry['Symbol'], parts.map(&:constant_value).map(&:raw_object).join.to_sym)
        end
      end
      
      add :@label do |node, text, location|
        node.is_constant = true
        wrap(node, ClassRegistry['Symbol'], text[0..-2].to_sym)
      end
      
      add :array do |node, parts|
        visit parts
        if (node.is_constant = parts.nil? || parts.all?(&:is_constant))
          value = parts.nil? ? [] : parts.map(&:constant_value).map(&:raw_object)
          wrap(node, ClassRegistry['Array'], value)
        end
      end
      
      add :var_ref do |node, ref|
        if ref.type == :@kw
          case ref[1]
          when 'nil'
            node.is_constant = true
            wrap(node, ClassRegistry['NilClass'], nil)
          when 'true'
            node.is_constant = true
            wrap(node, ClassRegistry['TrueClass'], true)
          when 'false'
            node.is_constant = true
            wrap(node, ClassRegistry['FalseClass'], false)
          when '__LINE__'
            node.is_constant = true
            wrap(node, ClassRegistry['Fixnum'], ref[2][0])
          end
        end
        visit_children(node)
      end
      
      add :dot2, :dot3 do |node, lhs, rhs|
        visit lhs
        visit rhs
        if (node.is_constant = lhs.is_constant && rhs.is_constant)
          node.is_constant = true
          if node.type == :dot2
            wrap(node, ClassRegistry['Range'], (lhs.constant_value.raw_object)..(rhs.constant_value.raw_object))
          else
            wrap(node, ClassRegistry['Range'], (lhs.constant_value.raw_object)...(rhs.constant_value.raw_object))
          end
        end
      end
      
      add :paren do |node, contents|
        visit contents
        if contents[0] != :params && (node.is_constant = contents.all?(&:is_constant))
          node.constant_value = contents.last.constant_value
        end
      end
    end
  end
end