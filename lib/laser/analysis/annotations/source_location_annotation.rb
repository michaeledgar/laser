module Laser
  module SexpAnalysis
    # This is a simple synthesized attribute applied to each node,
    # giving a pointer to that node's next and previous AST node.
    # That way AST traversal is easier.
    module SourceLocationAnnotation
      extend BasicAnnotation
      add_properties :source_begin, :source_end
      
      # This is the annotator for the next and prev annotation.
      class Annotator
        include Visitor
        
        def default_visit(node)
          visit_children(node)
          if (first_child = node.children.find { |child| Sexp === child })
            node.source_begin = first_child.source_begin
          end
          if (last_end = node.children.select { |child| Sexp === child }.map(&:source_end).compact.last)
            node.source_end = last_end
          end
        end
        
        add :@ident, :@int, :@kw, :@float, :@tstring_content, :@regexp_end,
            :@ivar, :@cvar, :@gvar, :@const, :@label, :@CHAR do |node, text, location|
          node.source_begin = location
          node.source_end = location.dup
          node.source_end[1] += text.size
        end
        
        add :regexp_literal do |node|
          default_visit node
          node.source_begin = node.source_begin.dup  # make a copy we can mutate
          if backtrack_expecting!(node.source_begin, -1, '/')
            # matched a / before the node
          elsif backtrack_expecting!(node.source_begin, -3, '%r')
            # matched a %r[]/%r{}/...
          end
        end
        
        add :string_literal do |node|
          default_visit node
          # make sure we have some hints as to source location
          if node.source_begin
            node.source_begin = node.source_begin.dup  # make a copy we can mutate
            node.source_end = node.source_end.dup  # make a copy we can mutate
            if backtrack_expecting!(node.source_begin, -1, "'") ||
               backtrack_expecting!(node.source_begin, -1, '"')
              # matched a single-quoted-string
              node.source_end[1] += 1
            end
          end
        end
        
        add :string_embexpr do |node|
          default_visit node
          if node.source_begin
            node.source_begin = node.source_begin.dup
            node.source_end = node.source_end.dup
            node.source_begin[1] -= 2  # always prefixed with #{
            node.source_end[1] += 1  # always suffixed with }
          end
        end
        
        add :dyna_symbol do |node|
          default_visit node
          if node.source_begin
            node.source_begin = node.source_begin.dup
            node.source_end = node.source_end.dup
            node.source_begin[1] -= 2  # always prefixed with :' or :"
            node.source_end[1] += 1  # always suffixed with "
          end
        end
        
        add :symbol_literal do |node|
          default_visit node
          node.source_begin = node.source_begin.dup
          node.source_begin[1] -= 1  # always prefixed with :
        end
        
        add :hash do |node|
          default_visit node
          # Ensure we found some source location hints
          if node.source_begin            
            node.source_begin = backtrack_searching(node.source_begin, '{')
            node.source_end = forwardtrack_searching(node.source_end, '}')
          end
        end
        
        add :array do |node|
          default_visit node
          # Ensure we found some source location hints
          if node.source_begin            
            node.source_begin = backtrack_searching(node.source_begin, '[')
            node.source_end = forwardtrack_searching(node.source_end, ']')
          end
        end
        
        add :def, :defs do |node|
          default_visit node
          node.source_begin = backtrack_searching(node.source_begin, 'def')
        end
        
        add :class, :sclass do |node|
          default_visit node
          node.source_begin = backtrack_searching(node.source_begin, 'class')
        end
        
        add :module do |node|
          default_visit node
          node.source_begin = backtrack_searching(node.source_begin, 'module')
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
        
        def text_at(location, offset, length)
          line = lines[location[0] - 1]
          line[location[1] + offset, length]
        end
      end
      add_global_annotator Annotator
    end
  end
end