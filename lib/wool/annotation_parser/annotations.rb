module Wool
  module Parsers
    module Annotation
      include Treetop::Runtime

      def root
        @root || :type
      end

      def _nt_type
        start_index = index
        if node_cache[:type].has_key?(index)
          cached = node_cache[:type][index]
          @index = cached.interval.end if cached
          return cached
        end

        i0 = index
        r1 = _nt_top
        if r1
          r0 = r1
        else
          r2 = _nt_self_type
          if r2
            r0 = r2
          else
            self.index = i0
            r0 = nil
          end
        end

        node_cache[:type][start_index] = r0

        return r0
      end

      module Top0
        def constraints
          []
        end
      end

      def _nt_top
        start_index = index
        if node_cache[:top].has_key?(index)
          cached = node_cache[:top][index]
          @index = cached.interval.end if cached
          return cached
        end

        if input.index("Top", index) == index
          r0 = instantiate_node(SyntaxNode,input, index...(index + 3))
          r0.extend(Top0)
          @index += 3
        else
          terminal_parse_failure("Top")
          r0 = nil
        end

        node_cache[:top][start_index] = r0

        return r0
      end

      module SelfType0
        def constraints
          [Constraints::SelfTypeConstraint.new]
        end
      end

      def _nt_self_type
        start_index = index
        if node_cache[:self_type].has_key?(index)
          cached = node_cache[:self_type][index]
          @index = cached.interval.end if cached
          return cached
        end

        if input.index("self", index) == index
          r0 = instantiate_node(SyntaxNode,input, index...(index + 4))
          r0.extend(SelfType0)
          @index += 4
        else
          terminal_parse_failure("self")
          r0 = nil
        end

        node_cache[:self_type][start_index] = r0

        return r0
      end

    end

    class AnnotationParser < Treetop::Runtime::CompiledParser
      include Annotation
    end

  end
end