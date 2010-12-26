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

        # Visits a module node and either creates or re-enters the corresponding scope, annotating the
        # body with that scope.
        add :module do |node, path_node, body|
          path_node, body = node.children
          default_visit(path_node)
          node.scope = @current_scope

          temp_cur_scope, new_mod_name = unpack_path(@current_scope, path_node)
          new_scope = temp_cur_scope.lookup_or_create_module(new_mod_name)
          visit_with_scope(body, new_scope)
        end

        # Visits a class node and either creates or re-enters a corresponding scope, annotating the
        # body with that scope.
        add :class do |node, path_node, superclass_node, body|
          if superclass_node
          then superclass = @current_scope.lookup_path(const_sexp_name(superclass_node)).self_ptr.value
          else superclass = ClassRegistry['Object']
          end
          
          default_visit(path_node)
          node.scope = @current_scope
          superclass_node.scope = @current_scope if superclass_node

          temp_cur_scope, new_class_name = unpack_path(@current_scope, path_node)
          new_scope = temp_cur_scope.lookup_or_create_class(new_class_name, superclass)
          visit_with_scope(body, new_scope)
        end

        add :def do |node, name, arglist, body|
          # Time to create a brand new WoolMethod!
          # Which class this is added to depends on the value of +self+.
          # 1. If self is a module or class (as is typical), the method is
          #    added to self's instance method list.
          # 2. If self does not have Module in its class hierarchy, then it
          #    should be added to self's singleton class. You can just skip
          #    the "class << self" or "def x.methodname" syntax.
          current_module = @current_scope.self_ptr.value
          new_signature = Signature.new(name, Protocols::UnknownProtocol.new)
          
        end

        add :defs do |node, singleton, op, name, arglist, body|
        end

        # Given a current scope and any possible way to describe a constant,
        # break it into two parts: the name of the final constant, and the
        # scope it will be in. The actual constant need not yet have an existing
        # object representing it yet – it will be lookup_or_created later.
        #
        # @param [Scope] current_scope the scope to look up the path in
        # @param [Sexp] path_node the node that describes the constant
        # @return [Array[Scope,String]] A tuple of the final scope and the
        #     name of the constant to use (as extracted from the AST)
        def unpack_path(current_scope, path_node)
          case path_node.type
          when :const_path_ref
            left, right = path_node.children
            new_class_name = const_sexp_name(right)
            current_scope = current_scope.lookup_path(const_sexp_name(left))
          when :top_const_ref
            current_scope = Scope::GlobalScope
            new_class_name = const_sexp_name(path_node)
          else
            new_class_name = const_sexp_name(path_node)
          end
          [current_scope, new_class_name]
        end

        # Evaluates the constant reference/path with the given scope
        # as context.
        def const_sexp_name(sexp)
          case sexp.type
          when :var_ref, :const_ref, :top_const_ref then sexp[1][1]
          when :@const then sexp[1]
          when :const_path_ref 
            left, right = sexp.children
            const_sexp_name(left) + '::' + const_sexp_name(right)
          end
        end
      end
      add_global_annotator Annotator
    end
  end
end