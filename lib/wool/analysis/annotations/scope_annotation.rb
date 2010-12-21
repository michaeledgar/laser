module Wool
  module SexpAnalysis
    # This is a *global* annotation, namely the one that determines the statically-known
    # scope for each node in the AST, at the time of that node's execution. For
    # example, every node should be able to say "hey scope, what's 'this' for this
    # statement?", and be able to return its type (*NOT* its class, they're different).
    module ScopeAnnotation
      extend BasicAnnotation
      add_property :scope
      
      # This is the annotator for the parent annotation.
      class Annotator
        attr_reader :scope_stack
        include Visitor
        def annotate!(root)
          @scope_stack = [Scope::GlobalScope]
          @current_scope = Scope::GlobalScope
          visit(root)
        end
        
        # Replaces the general node visit method with one that assigns
        # the current scope to the visited node.
        def default_visit(node)
          node.scope = @current_scope
          visit_children(node)
        end

        def visit_module(node)
          path_node, body = node.children
          [node, path_node, *path_node.all_subtrees].each do |subnode|
            subnode.scope = @current_scope
          end

          temp_cur_scope = @current_scope
          
          case path_node.type
          when :const_path_ref
            left, right = path_node.children
            new_mod_name = const_sexp_name(right)
            temp_cur_scope = temp_cur_scope.lookup_path(const_sexp_name(left))
          when :top_const_ref
            temp_cur_scope = Scope::GlobalScope
            new_mod_name = const_sexp_name(path_node)
          else
            new_mod_name = const_sexp_name(path_node)
          end

          new_scope = temp_cur_scope.lookup_or_create_module(new_mod_name)
          with_scope new_scope do
            visit(body)
          end
        end

        # 
        # def visit_class(node)
        #   path_to_new_class, superclass, body = node.children
        #   superclass = superclass ? superclass.eval_as_constant(@current_scope) : ClassRegistry['Object']
        # end

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

        # Evaluates the constant reference/path with the given scope
        # as context.
        def const_sexp_name(sexp)
          case sexp.type
          when :var_ref, :const_ref, :top_const_ref then sexp[1][1]
          when :@const then sexp[1]
          when :const_path_ref 
            left, right = children
            const_sexp_name(left) + '::' + const_sexp_name(right)
          end
        end
      end
      add_global_annotator Annotator
    end
  end
end