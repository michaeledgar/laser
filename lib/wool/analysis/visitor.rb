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
      
      def default_visit(node)
        node.children.select {|x| Sexp === x}.each {|x| visit(x) }
      end
      
      def method_missing(meth, *args, &blk)
        if meth.to_s[0,6] == 'visit_'
          default_visit args.first
        else
          raise
        end
      end
    end
  end
end