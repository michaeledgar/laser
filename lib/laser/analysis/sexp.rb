module Laser
  module SexpAnalysis
    # Replaces the ParseTree Sexps by adding a few handy-dandy methods.
    class Sexp < Array
      extend ModuleExtensions
      attr_accessor :errors, :binding, :file_name, :file_source

      # Initializes the Sexp with the contents of the array returned by Ripper.
      #
      # @param [Array<Object>] other the other 
      def initialize(other, file_name=nil, file_source=nil)
        @expr_type = nil
        @errors = []
        @file_name = file_name
        @file_source = file_source
        replace other
        replace_children!
      end
  
      # @return [Array<Object>] the children of the node.
      def children
        (Array === self[0] ? self : self[1..-1]) || []
      end
  
      # @return [Symbol] the type of the node.
      def type
        self[0]
      end

      # is the given object a sexp?
      #
      # @return Boolean
      def is_sexp?(sexp)
        SexpAnalysis::Sexp === sexp
      end

      def lines
        @file_source.lines.to_a
      end

      # Same as #find for Enumerable, only recursively. Useful for "jumping"
      # past useless parser nodes.
      def deep_find
        ([self] + all_subtrees.to_a).each do |node|
          return node if yield(node)
        end
      end
  
      def all_subtrees
        to_visit = self.children.dup
        visited = Set.new
        while to_visit.any?
          todo = to_visit.shift
          next unless is_sexp?(todo)

          case todo[0]
          when Array
            to_visit.concat todo
          when ::Symbol
            to_visit.concat todo.children
            visited << todo
          end
        end
        visited
      end
  
      # Returns an enumerator that iterates over each subnode of this node
      # in DFS order.
      def dfs_enumerator
        Enumerator.new do |g|
          dfs do |node|
            g.yield node
          end
        end
      end
  
      # Returns all errors in this subtree, in DFS order.
      # returns: [Error]
      def all_errors
        dfs_enumerator.map(&:errors).flatten
      end
  
      # Performs a DFS on the node, yielding each subnode (including the given node)
      # in DFS order.
      def dfs
        yield self
        self.children.each do |child|
          next unless is_sexp?(child)
          case child[0]
          when Array
            child.each { |x| x.dfs { |y| yield y}}
          when ::Symbol
            child.dfs { |y| yield y }
          end
        end
      end
  
      # Replaces the children with Sexp versions of them
      def replace_children!
        replace(map do |x|
          case x
          when Array
            self.class.new(x, @file_name, @file_source)
          else x
          end
        end)
      end
      private :replace_children!
      
      # Returns the text of the identifier, assuming this node identifies something.
      def expanded_identifier
        case type
        when :@ident, :@const, :@gvar, :@cvar, :@ivar, :@kw
          self[1]
        when :var_ref, :var_field, :const_ref
          self[1].expanded_identifier
        when :top_const_ref, :top_const_field
          "::#{self[1].expanded_identifier}"
        when :const_path_ref, :const_path_field
          lhs, rhs = children
          "#{lhs.expanded_identifier}::#{rhs.expanded_identifier}"
        end
      end
      
      # Finds the type of the AST node. This depends on the node's scope sometimes,
      # and always upon its node type.
      def expr_type
        return @expr_type if @expr_type
        case self.type
        when :string_literal, :@CHAR, :@tstring_content, :string_embexpr, :string_content,
             :xstring_literal
          @expr_type ||= Types::ClassType.new('String', :invariant)
        when :@int
          @expr_type ||= Types::ClassType.new('Integer', :covariant)
        when :@float
          @expr_type ||= Types::ClassType.new('Float', :invariant)
        when :regexp_literal
          @expr_type ||= Types::ClassType.new('Regexp', :invariant)
        when :hash, :bare_assoc_hash
          @expr_type ||= Types::ClassType.new('Hash', :invariant)
        when :symbol_literal, :dyna_symbol, :@label
          @expr_type ||= Types::ClassType.new('Symbol', :invariant)
        when :array
          @expr_type ||= Types::ClassType.new('Array', :invariant)
        when :dot2, :dot3 
          @expr_type ||= Types::ClassType.new('Range', :invariant)
        when :lambda 
          @expr_type ||= Types::ClassType.new('Proc', :invariant)
        when :var_ref
          ref = self[1]
          if ref.type == :@kw && ref.expanded_identifier != 'self'
            case ref[1]
            when 'nil' then @expr_type ||= Types::ClassType.new('NilClass', :invariant)
            when 'true' then @expr_type ||= Types::ClassType.new('TrueClass', :invariant)
            when 'false' then @expr_type ||= Types::ClassType.new('FalseClass', :invariant)
            when '__FILE__' then @expr_type ||= Types::ClassType.new('String', :invariant)
            when '__LINE__' then @expr_type ||= Types::ClassType.new('Fixnum', :invariant)
            when '__ENCODING__' then @expr_type ||= Types::ClassType.new('Encoding', :invariant)
            end
          else
            self.scope.lookup(expanded_identifier).expr_type rescue Types::TOP
          end
        else
          Types::TOP
        end
      end
      
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
          case self[1].type
          when :@kw
            %w(nil true false __LINE__ __FILE__).include?(expanded_identifier)
          else
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
            wrap(ClassRegistry['String'], char_part)
          else
            wrap(ClassRegistry['String'], eval(%Q{"#{char_part}"}))
          end
        when :@tstring_content
          str = self[1]
          pos = self.parent.parent.source_begin
          first_two = lines[pos[0]-1][pos[1],2]
          if first_two[0,1] == '"' || first_two == '%Q'
            wrap(ClassRegistry['String'], eval(%Q{"#{str}"}))
          else   
            wrap(ClassRegistry['String'], str)
          end
        when :string_content
          wrap(ClassRegistry['String'],
               children.map(&:constant_value).map(&:raw_object).join)
        when :string_literal, :symbol_literal
          self[1].constant_value
        when :@int
          wrap(ClassRegistry['Integer'], Integer(self[1]))
        when :@float
          wrap(ClassRegistry['Float'], Float(self[1]))
        when :@regexp_end
          str = self[1]
          result = 0
          result |= Regexp::IGNORECASE if str.include?('i')
          result |= Regexp::MULTILINE  if str.include?('m')
          result |= Regexp::EXTENDED   if str.include?('x')
          result
        when :regexp_literal
          parts, options = children
          wrap(ClassRegistry['Regexp'],
               Regexp.new(parts.map(&:constant_value).map(&:raw_object).join,
                 options.constant_value))
        when :assoc_new
          children.map(&:constant_value)
        when :assoclist_from_args, :bare_assoc_hash
          parts = self[1]
          wrap(ClassRegistry['Hash'],
               Hash[*parts.map(&:constant_value).flatten.map(&:raw_object)])
        when :hash
          part = self[1]
          part.nil? ? wrap(ClassRegistry['Hash'], {}) : part.constant_value
        when :symbol
          wrap(ClassRegistry['Symbol'], self[1][1].to_sym)
        when :dyna_symbol
          parts = self[1]
          wrap(ClassRegistry['Symbol'],
               parts.map(&:constant_value).map(&:raw_object).join.to_sym)
        when :@label
          wrap(ClassRegistry['Symbol'], self[1][0..-2].to_sym)
        when :array
          parts = self[1]
          value = parts.nil? ? [] : parts.map(&:constant_value).map(&:raw_object)
          wrap(ClassRegistry['Array'], value)
        when :var_ref, :const_path_ref, :const_ref, :var_field
          case self[1].type
          when :@kw
            case self[1][1]
            when 'nil' then wrap(ClassRegistry['NilClass'], nil)
            when 'true' then wrap(ClassRegistry['TrueClass'], true)
            when 'false' then wrap(ClassRegistry['FalseClass'], false)
            when '__LINE__' then wrap(ClassRegistry['Integer'], self[1][2][0])
            when '__FILE__' then wrap(ClassRegistry['String'], @file_name)
            end
          else
            scope.lookup(expanded_identifier).value
          end
        when :dot2
          lhs, rhs = children
          wrap(ClassRegistry['Range'],
               (lhs.constant_value.raw_object)..(rhs.constant_value.raw_object))
        when :dot3
          lhs, rhs = children
          wrap(ClassRegistry['Range'],
               (lhs.constant_value.raw_object)...(rhs.constant_value.raw_object))
        when :paren
          self[1].last.constant_value
        end
      end
      
      # Wraps a value in a constant proxy of the given class/name.
      def wrap(klass, name="#<#{klass.path}:#{object_id.to_s(16)}>", val)
        RealObjectProxy.new(klass, nil, name, val)
      end
    end
  end
end