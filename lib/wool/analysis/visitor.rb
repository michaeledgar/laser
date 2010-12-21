module Wool
  module SexpAnalysis
    # Visitor: a set of methods for visiting an AST. The
    # default implementations visit each child and do no
    # other processing. By including this module, and
    # implementing certain methods, you can do your own
    # processing on, say, every instance of a :rescue AST node.
    # The default implementation will go arbitrarily deep in the AST
    # tree until it hits a method you define.
    module Visitor
      extend ModuleExtensions
      def visit(node)
        case node
        when Sexp
          case node[0]
          when ::Symbol
            send("visit_#{node[0]}", node)
          when Array
            node.each {|x| visit(x)}
          end
        end
      end
      
      attr_accessor_with_default :scope_stack, [SexpAnalysis::Scope::GlobalScope]
      def enter_scope(scope)
        @current_scope = scope
        scope_stack.push scope
      end

      def exit_scope
        scope_stack.pop
        @current_scope = scope_stack.last
      end

      # Yields with the current scope preserved.
      def with_scope(scope)
        enter_scope scope
        yield
      ensure
        exit_scope
      end
      
      def visit_with_scope(node, scope)
        with_scope(scope) { visit(node) }
      end
      
      def visit_children(node)
        node.children.select {|x| Sexp === x}.each {|x| visit(x) }
      end
      alias_method :default_visit, :visit_children
      
      def method_missing(meth, *args, &blk)
        if meth.to_s[0,6] == 'visit_'
          default_visit args.first
        else
          super
        end
      end
    end
  end
end