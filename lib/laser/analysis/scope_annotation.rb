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
      add_property :scope
      depends_on :RuntimeAnnotation
      
      def annotate!(root)
        @current_scope = Scope::GlobalScope
        @visibility = :private
        super
      end
      
      # Replaces the general node visit method with one that assigns
      # the current scope to the visited node.
      def default_visit(node)
        node.scope = @current_scope
        visit_children(node)
      end
      
      # Load-time binding resolution. This should run *before* any method-matching, since
      # it directly affects method-matching!
      add :var_field do |node, ref|
        default_visit node
        node.binding = @current_scope.lookup(node.expanded_identifier)
      end
      
      # Here we handle Ruby's resolution of rvalues: if it looks like a local variable,
      # then we look it up, and if we fail, we assume it's a no-arg method call. If it
      # looks like a constant, then it's a constant!
      add :var_ref, :const_ref, :const_path_ref do |node, ref|
        default_visit node
        begin
          node.binding = @current_scope.lookup(node.expanded_identifier)
        rescue Scope::ScopeLookupFailure => err
          if err.query =~ /^[A-Z]/
            raise err
          end
        end
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
        with_visibility(:public) do
          visit_with_scope(body, new_scope)
        end
      end

      # Visits a class node and either creates or re-enters a corresponding scope, annotating the
      # body with that scope.
      # TODO(adgar): raise if this occurs within a method definition
      add :class do |node, path_node, superclass_node, body|
        # TODO(adgar): Make this do real lookup.
        visit superclass_node
        if superclass_node && superclass_node.is_constant
        then superclass = superclass_node.constant_value
        elsif superclass_node 
          raise DynamicSuperclassError.new(
              "Superclass of #{path_node.expanded_identifier}" +
              " is not a constant value. bad idea!", superclass_node)
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
        with_visibility(:public) do
          visit_with_scope(body, new_scope)
        end
      end
      
      # Provides a general-purpose method for looking up a binding,
      # and yielding on failure.
      def lookup_or_create(scope, name)
        begin
          scope.lookup(name).value.scope
        rescue Scope::ScopeLookupFailure => err
          yield
        end
      end

      # Looks up a module, and creates it on failure.
      def lookup_or_create_module(scope, new_mod_name)
        lookup_or_create(scope, new_mod_name) do
          new_scope = ClosedScope.new(scope, nil)
          new_mod = LaserModule.new(ClassRegistry['Module'], new_scope, new_mod_name)
          new_scope
        end
      end

      # Looks up a class, and creates it on failure.
      def lookup_or_create_class(scope, new_class_name, superclass)
        lookup_or_create(scope, new_class_name) do
          new_scope = ClosedScope.new(scope, nil)
          new_class = LaserClass.new(ClassRegistry['Class'], new_scope, new_class_name) do |klass|
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
          current_scope = current_scope.lookup(left.expanded_identifier).value.scope
        when :top_const_ref
          current_scope = Scope::GlobalScope
          new_class_name = path_node.expanded_identifier
        else
          new_class_name = path_node.expanded_identifier
        end
        [current_scope, new_class_name]
      end

      # Enter the singleton class.
      add :sclass do |node, singleton, body|
        visit singleton
        method_self = @current_scope.lookup(singleton.expanded_identifier).value
        receiver = method_self.singleton_class
        singleton.scope = @current_scope
        visit_with_scope(body, receiver.scope)
      end

      ######## Detecting includes - requires method call detection! ########
      match_method_call 'include' do |node, args|
        default_visit node
        if node.runtime == :load && @current_scope.self_ptr.klass.ancestors.include?(ClassRegistry['Module']) && args.is_constant?
          args.constant_values.reverse.each do |arg|
            @current_scope.self_ptr.include_module(arg)
          end
        end
      end
      
      match_method_call 'extend' do |node, args|
        default_visit node
        if node.runtime == :load && @current_scope.self_ptr.klass.ancestors.include?(ClassRegistry['Module']) && args.is_constant?
          args.constant_values.reverse.each do |arg|
            @current_scope.self_ptr.singleton_class.include_module(arg)
          end
        end
      end
      
      def implicit_receiver
        if @current_scope.parent.nil?
        then receiving_class = ClassRegistry['Object']
        else receiving_class = @current_scope.self_ptr
        end
      end
      
      def apply_visibility(node, args, visibility)
        default_visit node
        if @current_scope.parent.nil? && visibility == :protected
          # node.errors << NoSuchMethodError.new("No 'protected' method at the top level.", node)
        elsif node.runtime == :load && (@current_scope.parent.nil? ||
           @current_scope.self_ptr.klass.ancestors.include?(ClassRegistry['Module']))
          if args.empty?
            @visibility = visibility
          elsif args.is_constant?
            receiving_class = implicit_receiver

            args.constant_values.map(&:to_s).each do |method_name|
              found_method = receiving_class.instance_methods[method_name]
              if found_method.owner != receiving_class
                found_method = found_method.dup
                receiving_class.add_instance_method!(found_method)
              end
              found_method.visibility = visibility
            end
          end
        end
      end
      
      match_method_call 'private' do |node, args|
        apply_visibility node, args, :private
      end
      
      match_method_call 'public' do |node, args|
        apply_visibility node, args, :public
      end
      
      match_method_call 'protected' do |node, args|
        apply_visibility node, args, :protected
      end

      # Normal method definitions.
      add :def do |node, (_, name), arglist, body|
        receiver = implicit_receiver

        new_signature = Signature.for_definition_sexp(name, arglist, body)
        new_method = LaserMethod.new(name, @visibility) do |method|
          method.body_ast = body
          method.add_signature!(new_signature)
        end
        receiver.add_instance_method!(new_method)

        method_locals = Hash[new_signature.arguments.map { |arg| [arg.name, arg] }]
        new_scope = ClosedScope.new(@current_scope, nil, {}, method_locals)
        
        if LaserModule === receiver
        then method_self = receiver.get_instance(new_scope)
        else method_self = receiver
        end
        if new_scope.self_ptr.nil?
          new_scope.self_ptr = method_self
          new_scope.locals['self'].expr_type = Types::ClassType.new(method_self.klass.path, :covariant)
        end
        new_scope.method = new_method
        
        visit_with_scope(arglist, new_scope)
        visit_with_scope(body, new_scope)
      end

      # Singleton method definition: def receiver.method_name
      add :defs do |node, singleton, op, (_, name), arglist, body|
        visit singleton
        method_self = @current_scope.lookup(singleton.expanded_identifier).value
        receiver = method_self.singleton_class
        add_method_to_object(receiver, method_self, name, arglist, body)
      end

      def add_method_to_object(receiver, method_self, name, arglist, body)
        new_signature = Signature.for_definition_sexp(name, arglist, body)
        new_method = LaserMethod.new(name, @visibility) do |method|
          method.body_ast = body
          method.add_signature!(new_signature)
        end
        receiver.add_instance_method!(new_method)

        method_locals = Hash[new_signature.arguments.map { |arg| [arg.name, arg] }]
        new_scope = ClosedScope.new(@current_scope, method_self, {}, method_locals)
        new_scope.method = new_method
        
        visit_with_scope(arglist, new_scope)
        visit_with_scope(body, new_scope)
      end
      
      # On assignment: ensure bindings exist for all vars on the LHS
      add :assign, :massign do |node, names, vals|
        assgn_expression = AssignmentExpression.new(node)
        bind_variable_names(assgn_expression.lhs.names)
        node.scope = @current_scope
        visit names
        visit vals
        
        if assgn_expression.is_constant
          binding_pairs = assgn_expression.assignment_pairs
          binding_pairs.each do |name, val|
            if name.expanded_identifier =~ /^[A-Z]/
              @current_scope.lookup(name.expanded_identifier).bind!(val, true)
            end
          end
        end
      end
      
      # Ensures bindings exist for the given variable names.
      def bind_variable_names(names)
        names = names.compact  # nil in 'names' represents a field, i.e. abc.foo = or abc[foo] =
        unless names.all? { |name| @current_scope.sees_var?(name) }
          names.each do |name|
            next if @current_scope.sees_var?(name)
            binding_class = case name
                            when /^[A-Z]/ then Bindings::ConstantBinding
                            else Bindings::LocalVariableBinding
                            end
            value = LaserObject.new(ClassRegistry['Object'], @current_scope)
            binding = binding_class.new(name, value)
            @current_scope.add_binding!(binding)
          end
        end
      end
      
      # For loop: just ensure bindings exist for the given variables.
      add :for do |node, vars, iterable, body|
        lhs = LHSExpression.new(vars)
        all_var_names = lhs.names
        bind_variable_names(all_var_names)
        all_var_names.select { |name| name =~ /^[A-Z]/ }.each do |const|
          node.errors << ConstantInForLoopError.new(const, node)
        end
        node.scope = @current_scope
        visit vars
        visit body
      end
      
      # any block *at all*: check for arguments, create a new scope with those arguments.
      add :method_add_block do |node, callnode, blocknode|
        argnode, body = blocknode.children
        arglist = argnode ? Signature.arg_list_for_arglist(argnode[1]) : []
        
        method_locals = Hash[arglist.map { |arg| [arg.name, arg] }]
        new_scope = OpenScope.new(@current_scope, @current_scope.self_ptr, {}, method_locals)
        visit_with_scope(argnode, new_scope) if argnode
        visit_with_scope(body, new_scope)
      end
      
      ################## Scope management methods #######################

      # Yields with the current visibility preserved.
      def with_visibility(visibility)
        old_visibility, @visibility = @visibility, visibility
        yield
      ensure
        @visibility = old_visibility
      end
      
      def visit_with_visibility(node, visibility)
        with_visibility(visibility) { visit(node) }
      end

      # Yields with the current scope preserved.
      def with_scope(scope)
        old_scope, @current_scope = @current_scope, scope
        yield
      ensure
        @current_scope = old_scope
      end
      
      def visit_with_scope(node, scope)
        with_scope(scope) { visit(node) }
      end
    end
  end
end