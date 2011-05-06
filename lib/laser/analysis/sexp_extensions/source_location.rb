module Laser::SexpAnalysis
  module SexpExtensions
    module SourceLocation
      
      def line_number
        source_begin && source_begin[0]
      end
      
      # Calculates, with some lossiness, the start position of the current node
      # in the original text. This will sometimes fail, as the AST does not include
      # sufficient information in many cases to determine where a node lies. We
      # have to figure it out based on nearby identifiers and keywords.
      def source_begin
        return @source_begin if @source_begin
        default_result = children.select { |child| Sexp === child }.
                                  map(&:source_begin).compact.first
        @source_begin = 
            case type
            when :@ident, :@int, :@kw, :@float, :@tstring_content, :@regexp_end,
                 :@ivar, :@cvar, :@gvar, :@const, :@label, :@CHAR, :@op
              children[1]
            when :regexp_literal
              result = default_result.dup
              if backtrack_expecting!(result, -1, '/') || backtrack_expecting!(result, -3, '%r')
                result
              end
            when :string_literal
              if default_result
                result = default_result.dup  # make a copy we can mutate
                if backtrack_expecting!(result, -1, "'") ||
                   backtrack_expecting!(result, -1, '"') ||
                   backtrack_expecting!(result, -3, '%q') ||
                   backtrack_expecting!(result, -3, '%Q')
                  result
                end
              end
            when :string_embexpr
              if default_result
                result = default_result.dup
                result[1] -= 2
                result
              end
            when :dyna_symbol
              if default_result
                result = default_result.dup
                result[1] -= 2
                result
              end
            when :symbol_literal
              result = default_result.dup
              result[1] -= 1
              result
            when :hash
              backtrack_searching(default_result, '{') if default_result
            when :array
              backtrack_searching(default_result, '[') if default_result
            when :def, :defs
              backtrack_searching(default_result, 'def')
            when :class, :sclass
              backtrack_searching(default_result, 'class')
            when :module
              backtrack_searching(default_result, 'module')
            else
              default_result
            end
      end
      
      # Calculates, with some lossiness, the end position of the current node
      # in the original text. This will sometimes fail, as the AST does not include
      # sufficient information in many cases to determine where a node ends. We
      # have to figure it out based on nearby identifiers, keywords, and literals.
      def source_end
        default_result = children.select { |child| Sexp === child }.
                                  map(&:source_end).compact.last
        case type
        when :@ident, :@int, :@kw, :@float, :@tstring_content, :@regexp_end,
             :@ivar, :@cvar, :@gvar, :@const, :@label, :@CHAR, :@op
          text, location = children
          source_end = location.dup
          source_end[1] += text.size
          source_end
        when :string_literal
          if source_begin
            result = default_result.dup
            result[1] += 1
            result
          end
        when :string_embexpr, :dyna_symbol
          if default_result
            result = default_result.dup
            result[1] += 1
            result
          end
        when :hash
          forwardtrack_searching(default_result, '}') if default_result
        when :array
          forwardtrack_searching(default_result, ']') if default_result
        else
          default_result
        end
      end
      
      # Searches for the given text starting at the given location, going backwards.
      # Modifies the location to match the discovered expected text on success.
      #
      # complexity: O(N) wrt input source
      # location: [Fixnum, Fixnum]
      # expectation: String
      # returns: Boolean
      def backtrack_searching(location, expectation)
        result = location.dup
        line = lines[result[0] - 1]
        begin
          if (expectation_location = line.rindex(expectation, result[1]))
            result[1] = expectation_location
            return result
          end
          result[0] -= 1
          line = lines[result[0] - 1]
          result[1] = line.size
        end while result[0] >= 0
        location
      end
      
      # Searches for the given text starting at the given location, going backwards.
      # Modifies the location to match the discovered expected text on success.
      #
      # complexity: O(N) wrt input source
      # location: [Fixnum, Fixnum]
      # expectation: String
      # returns: Boolean
      def forwardtrack_searching(location, expectation)
        result = location.dup
        line = lines[result[0] - 1]
        begin
          if (expectation_location = line.index(expectation, result[1]))
            result[1] = expectation_location + expectation.size
            return result
          end
          result[0] += 1
          result[1] = 0
          line = lines[result[0] - 1]
        end while result[0] <= lines.size
        location
      end
      
      # Attempts to backtrack for the given string from the given location.
      # Returns true if successful.
      def backtrack_expecting!(location, offset, expectation)
        if text_at(location, offset, expectation.length) == expectation
          location[1] += offset
          true
        end
      end
      
      # Determines the text at the given location tuple, with some offset,
      # and a given length.
      def text_at(location, offset, length)
        line = lines[location[0] - 1]
        line[location[1] + offset, length]
      end
    end
  end
end