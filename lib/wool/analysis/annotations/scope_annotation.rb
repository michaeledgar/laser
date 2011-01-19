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
          new_scope = lookup_or_create_module(temp_cur_scope, new_mod_name)
          visit_with_scope(body, new_scope)
        end

        # Visits a class node and either creates or re-enters a corresponding scope, annotating the
        # body with that scope.
        add :class do |node, path_node, superclass_node, body|
          if superclass_node
          then superclass = @current_scope.lookup_path(const_sexp_name(superclass_node)).self_ptr
          else superclass = ClassRegistry['Object']
          end
          default_visit(path_node)
          node.scope = @current_scope
          superclass_node.scope = @current_scope if superclass_node

          temp_cur_scope, new_class_name = unpack_path(@current_scope, path_node)
          new_scope = lookup_or_create_class(temp_cur_scope, new_class_name, superclass)
          visit_with_scope(body, new_scope)
        end
        
        # Provides a general-purpose method for looking up a binding,
        # and yielding on failure.
        def lookup_or_create(scope, name)
          begin
            scope.lookup(name).scope
          rescue Scope::ScopeLookupFailure => err
            yield
          end
        end

        # Looks up a module, and creates it on failure.
        def lookup_or_create_module(scope, new_mod_name)
          lookup_or_create(scope, new_mod_name) do
            new_scope = ClosedScope.new(scope, nil)
            new_mod = WoolModule.new(submodule_path(scope, new_mod_name), new_scope)
            new_scope
          end
        end

        # Looks up a class, and creates it on failure.
        def lookup_or_create_class(scope, new_class_name, superclass)
          lookup_or_create(scope, new_class_name) do
            new_scope = ClosedScope.new(scope, nil)
            new_class = WoolClass.new(submodule_path(scope, new_class_name), new_scope) do |klass|
              klass.superclass = superclass
            end
            new_scope
          end
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
        # as describe.
        def const_sexp_name(sexp)
          case sexp.type
          when :var_ref, :const_ref, :top_const_ref then sexp[1][1]
          when :@const then sexp[1]
          when :const_path_ref 
            left, right = sexp.children
            const_sexp_name(left) + '::' + const_sexp_name(right)
          end
        end
        
        # Looks up the local and returns it – initializing it to nil (as Ruby does)
        def lookup_or_create_local(local_name)
          locals[local_name] ||= LocalBinding.new(local_name, nil)
        end

        # Returns the canonical path for a (soon-to-be-created) submodule of the given
        # scope. This is computed before creating the module.
        #
        # TODO(adgar): make this compute inside the WoolModule/WooLClass constructors.
        def submodule_path(scope, new_mod_name)
          new_mod_full_path = scope == Scope::GlobalScope ? '' : scope.path
          new_mod_full_path += "::" unless new_mod_full_path.empty?
          new_mod_full_path += new_mod_name
        end

        # Enter the singleton class.
        add :sclass do |node, (_, singleton), body|
          method_self = @current_scope.lookup(singleton.children.first).value
          receiver = method_self.singleton_class
          singleton.scope = @current_scope
          visit_with_scope(body, receiver.scope)
        end

        # Normal method definitions.
        add :def do |node, (_, name), arglist, body|
          receiver = @current_scope.self_ptr
          # Time to create a brand new WoolMethod!
          # Which class this is added to depends on the value of +self+.
          # 1. If self is a module or class (as is typical), the method is
          #    added to self's instance method list.
          # 2. If self does not have Module in its class hierarchy, then it
          #    should be added to self's singleton class.
          if WoolModule === receiver
          then method_self = receiver.get_instance
          else method_self = receiver
          end

          add_method_to_object(receiver, method_self, name, arglist, body)
        end

        # Singleton method definition: def receiver.method_name
        add :defs do |node, (_, singleton), op, (_, name), arglist, body|
          method_self = @current_scope.lookup(singleton.children.first).value
          receiver = method_self.singleton_class
          add_method_to_object(receiver, method_self, name, arglist, body)
        end

        def add_method_to_object(receiver, method_self, name, arglist, body)
          new_signature = Signature.for_definition_sexp(name, arglist, body)
          receiver.add_instance_method!(WoolMethod.new(name) do |method|
            method.add_signature!(new_signature)
          end)

          method_locals = Hash[new_signature.arguments.map { |arg| [arg.name, arg] }]
          new_scope = ClosedScope.new(@current_scope, method_self, {}, method_locals)
          visit_with_scope(body, new_scope)
        end
        
        # Single assignment. Update/Create 1 binding.
        add :assign do |node, name, val|
          begin
            @current_scope.lookup(name[1][1])
          rescue Scope::ScopeLookupFailure
            object = WoolObject.new(ClassRegistry['Object'], @current_scope)
            create_binding(name[1], object)
          end
          node.scope = @current_scope
          visit name
          visit val
        end
        
        # Creates a binding for a thus-far unbound name.
        # This *only* applies to local variables and constants! All other binding types
        # ($globals, @ivars, @@cvars) are all created on-demand when looked up, and this
        # is reflected in the Scope#lookup method.
        def create_binding(name_sexp, value)
          raw_name = name_sexp[1]
          binding_class = case name_sexp.type
                          when :@ident then Bindings::LocalVariableBinding
                          when :@const then Bindings::ConstantBinding
                          end
          @current_scope = @current_scope.dup
          binding = binding_class.new(raw_name, value)
          @current_scope.add_binding!(binding)
        end
        
        add :massign do |node, names, vals|
          all_binding_names = extract_names(names)
          unless all_names_exist?(names)
            @current_scope = @current_scope.dup
            all_binding_names.each do |name|
              begin
                @current_scope.lookup(name)
              rescue
                binding_class = case name[0,1]
                                when /[A-Z]/ then Bindings::ConstantBinding
                                else Bindings::LocalVariableBinding
                                end
                value = WoolObject.new(ClassRegistry['Object'], @current_scope)
                binding = binding_class.new(name, value)
                @current_scope.add_binding!(binding)
              end
            end
          end
          node.scope = @current_scope
          visit names
          visit vals
        end
        
        def extract_names(node)
          case node[0]
          when Array then node.map { |x| extract_names(x) }.flatten
          when :mlhs_paren then extract_names(node[1])
          when :mlhs_add_star then node.children.map { |x| extract_names(x) }.flatten
          when :@ident, :@const, :@gvar, :@ivar, :@cvar then node[1]
          end
        end

        def all_names_exist?(names)
          names.all { |name| @current_scope.lookup(name) } rescue false
        end
        
        # add :for do |sym, vars, iterable, body|
        #   case vars.first
        #   when :var_field
        #     # one variable
        #   when Sexp
        #     # vars is an array of variables
        #   end
        # end
      end
      add_global_annotator Annotator
    end
  end
end