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
          @scope_stack = []
          @current_scope = Scope::GlobalScope
          visit(root)
        end
        
        # Replaces the general node visit method with one that assigns
        # the current scope to the visited node.
        def default_visit(node)
          node.scope = @current_scope
          visit_children(node)
        end

        def constant_name(const)
          case const.type
          # [:var_ref, [:@const, "B", [1, 17]]]
          when :var_ref then return const[1][1]
          # [:const_ref, [:@const, "M", [1, 17]]]
          when :const_ref then return const[1][1]
          # [:top_const_ref, [:@const, "M", [1, 2]]]
          when :top_const_ref then return const[1][1]
          # [:@const, "B", [1, 7]]
          when :@const then return const[1]
          end
        end

        def visit_module(node)
          temp_cur_scope = @current_scope
          path_node, body = node.children
          case path_node.type
          # [:top_const_ref, [:@const, "M", [1, 2]]]
          when :top_const_ref
            temp_cur_scope = Scope::GlobalScope
            new_mod_name = path_node
          # [:const_path_ref, [:var_ref, [:@const, "B", [1, 17]]], [:@const, "M", [1, 20]]]
          when :const_path_ref
            left, right = children
            temp_cur_scope = left.eval_as_constant(scope).scope
            new_mod_name = constant_name right
          else
            new_mod_name = constant_name path_node
          end
          new_mod_full_path = scope_path(temp_cur_scope)
          new_mod_full_path << "::" unless new_mod_full_path.empty?
          new_mod_full_path << new_mod_name
          new_mod = WoolModule.new(new_mod_full_path, temp_cur_scope)
          instance = Symbol.new(new_mod.protocol, new_mod)
          instance.name = new_mod_name
          instance.scope = temp_cur_scope
          
          temp_cur_scope.constants[new_mod_name] = instance
          new_scope = Scope.new(temp_cur_scope, instance)
          with_scope new_scope do
            visit(body)
          end
        end
        # 
        # def visit_class(node)
        #   path_to_new_class, superclass, body = node.children
        #   superclass = superclass ? superclass.eval_as_constant(@current_scope) : ClassRegistry['Object']
        # end
        
        def scope_path(current)
          (scope_stack + [current]).map {|x| x.self_ptr.name}.join('::')
        end
        
        def enter_scope(scope)
          @current_scope = scope
          scope_stack.push scope
        end
        
        def exit_scope
          @current_scope = scope_stack.pop
        end
        
        # Yields with the current scope preserved.
        def with_scope(scope)
          enter_scope scope
          yield
        ensure
          exit_scope
        end
      end
      add_global_annotator Annotator
    end
  end
end