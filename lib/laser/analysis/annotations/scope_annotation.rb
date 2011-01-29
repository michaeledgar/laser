module Laser
  module SexpAnalysis
    # This is a *global* annotation, namely the one that determines the statically-known
    # scope for each node in the AST, at the time of that node's execution. For
    # example, every node should be able to say "hey scope, what's 'this' for this
    # statement?", and be able to return its type (*NOT* its class, they're different).
    #
    # Depends on: ExpandedIdentifierAnnotation
    # This is the annotator for the parent annotation.
    class ScopeAnnotation < BasicAnnotation
      class ReopenedClassAsModuleError < Laser::Error
        severity MAJOR_ERROR
      end
      class ReopenedModuleAsClassError < Laser::Error
        severity MAJOR_ERROR
      end

      add_property :scope
      depends_on :RuntimeAnnotation
      depends_on :ExpandedIdentifierAnnotation
      
      def annotate!(root)
        @current_scope = Scope::GlobalScope
        super
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
        if new_scope.self_ptr.klass == ClassRegistry['Class']
          node.errors << ReopenedClassAsModuleError.new("Opened class #{new_scope.self_ptr.name} as a module.", node)
        end
        visit_with_scope(body, new_scope)
      end

      # Visits a class node and either creates or re-enters a corresponding scope, annotating the
      # body with that scope.
      # TODO(adgar): raise if this occurs within a method definition
      add :class do |node, path_node, superclass_node, body|
        # TODO(adgar): Make this do real lookup.
        if superclass_node
        then superclass = @current_scope.proper_variable_lookup(superclass_node.expanded_identifier)
        else superclass = ClassRegistry['Object']
        end
        default_visit(path_node)
        node.scope = @current_scope
        superclass_node.scope = @current_scope if superclass_node

        temp_cur_scope, new_class_name = unpack_path(@current_scope, path_node)
        new_scope = lookup_or_create_class(temp_cur_scope, new_class_name, superclass)
        if new_scope.self_ptr.klass != ClassRegistry['Class']
          node.errors << ReopenedModuleAsClassError.new("Opened module #{new_scope.self_ptr.name} as a class.", node)
        end
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
          new_mod = LaserModule.new(new_mod_name, new_scope)
          new_scope
        end
      end

      # Looks up a class, and creates it on failure.
      def lookup_or_create_class(scope, new_class_name, superclass)
        lookup_or_create(scope, new_class_name) do
          new_scope = ClosedScope.new(scope, nil)
          new_class = LaserClass.new(new_class_name, new_scope) do |klass|
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
          new_class_name = right.expanded_identifier
          current_scope = current_scope.proper_variable_lookup(left.expanded_identifier).scope
        when :top_const_ref
          current_scope = Scope::GlobalScope
          new_class_name = path_node.expanded_identifier
        else
          new_class_name = path_node.expanded_identifier
        end
        [current_scope, new_class_name]
      end

      # Enter the singleton class.
      add :sclass do |node, (_, singleton), body|
        method_self = @current_scope.lookup(singleton.children.first).value
        receiver = method_self.singleton_class
        singleton.scope = @current_scope
        visit_with_scope(body, receiver.scope)
      end

      ######## Detecting includes - requires method call detection! ########
      # TODO(adgar): Write a helper that matches method calls in the general case
      add :command do |node, ident, args|
        if node.runtime == :load && ident[1] == 'include' && args &&
           @current_scope.self_ptr.klass.ancestors.include?(ClassRegistry['Module'])
          args[1].reverse.each do |arg|
            if arg.expanded_identifier
              @current_scope.self_ptr.include_module(
                  @current_scope.proper_variable_lookup(arg.expanded_identifier))
            end
          end
        else
          default_visit node
        end
      end

      # Normal method definitions.
      add :def do |node, (_, name), arglist, body|
        receiver = @current_scope.self_ptr
        # Time to create a brand new LaserMethod!
        # Which class this is added to depends on the value of +self+.
        # 1. If self is a module or class (as is typical), the method is
        #    added to self's instance method list.
        # 2. If self does not have Module in its class hierarchy, then it
        #    should be added to self's singleton class.
        if LaserModule === receiver
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
        receiver.add_instance_method!(LaserMethod.new(name) do |method|
          method.add_signature!(new_signature)
        end)

        method_locals = Hash[new_signature.arguments.map { |arg| [arg.name, arg] }]
        new_scope = ClosedScope.new(@current_scope, method_self, {}, method_locals)
        visit_with_scope(body, new_scope)
      end
      
      add :assign, :massign do |node, names, vals|
        bind_variable_names(extract_names(names))
        node.scope = @current_scope
        visit names
        visit vals
      end
      
      def bind_variable_names(names)
        unless names.all? { |name| @current_scope.sees_var?(name) }
          @current_scope = @current_scope.dup
          names.each do |name|
            next if @current_scope.sees_var?(name)
            binding_class = case name[0,1]
                            when /[A-Z]/ then Bindings::ConstantBinding
                            else Bindings::LocalVariableBinding
                            end
            value = LaserObject.new(ClassRegistry['Object'], @current_scope)
            binding = binding_class.new(name, value)
            @current_scope.add_binding!(binding)
          end
        end
      end
      
      def extract_names(node)
        case node[0]
        when Array then node.map { |x| extract_names(x) }.flatten
        when :field, :aref_field then []  # useless for discovering names and new scopes
        when :var_field then [extract_names(node[1])]
        when :mlhs_paren then extract_names(node[1])
        when :mlhs_add_star then node.children.map { |x| extract_names(x) }.flatten
        when :@ident, :@const, :@gvar, :@ivar, :@cvar then node[1]
        end
      end
      
      add :for do |node, vars, iterable, body|
        bind_variable_names(extract_names(vars))
        node.scope = @current_scope
        visit vars
        visit body
      end
      
      add :method_add_block do |node, callnode, blocknode|
        argnode, body = blocknode.children
        arglist = Signature.arg_list_for_arglist(argnode[1])
        
        method_locals = Hash[arglist.map { |arg| [arg.name, arg] }]
        new_scope = OpenScope.new(@current_scope, @current_scope.self_ptr, {}, method_locals)
        visit_with_scope(body, new_scope)
      end
    end
  end
end