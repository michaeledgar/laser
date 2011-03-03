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
        @module_function = false
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
        if singleton.is_constant
          method_self = singleton.constant_value
          receiver = method_self.singleton_class
          singleton.scope = @current_scope
          visit_with_scope(body, receiver.scope)
        end
      end

      def include_modules(klass, mods)
        mods.reverse.each { |arg| klass.include_module(arg) }
      end

      match_precise_loadtime_method(proc { 
            [ClassRegistry['Module'].instance_methods['include']]}) do |node, args|
        if args.is_constant?
          include_modules(@current_scope.self_ptr, args.constant_values)
        end
      end
      
      match_precise_loadtime_method(proc { 
            [ClassRegistry['Module'].instance_methods['extend']]}) do |node, args|
        if args.is_constant?
          include_modules(@current_scope.self_ptr.singleton_class, args.constant_values)
        end
      end
      
      def implicit_receiver
        if @current_scope.parent.nil?
        then receiving_class = ClassRegistry['Object']
        else receiving_class = @current_scope.self_ptr
        end
      end
      
      def apply_visibility(args, visibility)
        if args.nil? || args.empty?
          @visibility = visibility
          @module_function = false
        elsif args.is_constant?
          receiving_class = implicit_receiver

          args.constant_values.map(&:to_s).each do |method_name|
            receiving_class.set_visibility!(method_name, visibility)
          end
        end
      end
      
      # Visibility emulation.
      # module_function also applies private visibility, but we'll need
      # a second hook later to apply the singleton duplicator bit.
      match_precise_loadtime_method(proc { 
            [ClassRegistry['Module'].instance_methods['private'],
             Scope::GlobalScope.self_ptr.singleton_class.instance_methods['private'],
             ClassRegistry['Module'].instance_methods['module_function']]}) do |node, args|
        apply_visibility args, :private
      end
      
      match_precise_loadtime_method(proc { 
            [ClassRegistry['Module'].instance_methods['public'],
             Scope::GlobalScope.self_ptr.singleton_class.instance_methods['public']]}) do |node, args|
        apply_visibility args, :public
      end
      
      match_precise_loadtime_method(proc { 
            [ClassRegistry['Module'].instance_methods['protected']]}) do |node, args|
        apply_visibility args, :protected
      end
      
      match_precise_loadtime_method(proc { 
            [ClassRegistry['Module'].instance_methods['module_function']]}) do |node, args|
        if args.nil? || args.empty?
          @module_function = true
        elsif args.is_constant?
          receiving_class = implicit_receiver
          args.constant_values.map(&:to_s).each do |method_name|
            found_method = receiving_class.instance_methods[method_name].dup
            receiving_class.singleton_class.add_instance_method!(found_method)
            receiving_class.singleton_class.set_visibility!(found_method.name, :public)
          end
        end
      end

      # Normal method definitions.
      add :def do |node, (_, name), arglist, body|
        receiver = implicit_receiver

        new_method, method_locals = build_new_method(receiver, name, arglist, body)
        new_scope = ClosedScope.new(@current_scope, nil, {}, method_locals)
        
        if LaserModule === receiver
        then method_self = receiver.get_instance(new_scope)
        else method_self = receiver
        end
        new_scope.self_ptr = method_self
        
        attach_new_method_scope(new_method, new_scope, arglist, body)
      end

      # Singleton method definition: def receiver.method_name
      add :defs do |node, singleton, op, (_, name), arglist, body|
        visit singleton
        method_self = @current_scope.lookup(singleton.expanded_identifier).value
        receiver = method_self.singleton_class

        new_method, method_locals = build_new_method(receiver, name, arglist, body)

        new_scope = ClosedScope.new(@current_scope, method_self, {}, method_locals)
        attach_new_method_scope(new_method, new_scope, arglist, body)
      end
      
      # Builds a new method based on the content of the definition node.
      #
      # return: (LaserMethod, String => Argument)
      def build_new_method(receiver, name, arglist, body)
        new_signature = Signature.for_definition_sexp(name, arglist, body)
        new_method = LaserMethod.new(name, @visibility) do |method|
          method.body_ast = body
          method.add_signature!(new_signature)
        end
        receiver.add_instance_method!(new_method)
        receiver.set_visibility!(new_method.name, @visibility)
        if @module_function
          duplicate_method = new_method.dup
          receiver.singleton_class.add_instance_method!(duplicate_method)
          receiver.singleton_class.set_visibility!(duplicate_method.name, :public)
        end
        [new_method, extract_signature_locals(new_signature)]
      end
      
      # Attaches the given scope to the newly created method. This will
      # require setting the method attribute on the new scope as well as
      # visiting the body and argument list with the new scope.
      #
      # Visiting the argument list is done because optional arguments can
      # perform arbitrary computations.
      def attach_new_method_scope(new_method, new_scope, arglist, body)
        new_scope.method = new_method        
        visit_with_scope(arglist, new_scope)
        visit_with_scope(body, new_scope)
      end
      
      # Extracts the signature's arguments as a hash.
      #
      # returns: String => Argument
      def extract_signature_locals(new_signature)
        Hash[new_signature.arguments.map { |arg| [arg.name, arg] }]
      end
      
      # Handles keyword aliases: alias keyword uses the lexical value of self
      add :alias do |node, new, old|
        next unless node.runtime == :load
        current_self = @current_scope.self_ptr
        new_name, old_name = new[1].expanded_identifier, old[1].expanded_identifier
        if current_self.instance_methods[old_name]
          current_self.alias_instance_method!(new_name, old_name)
        else
          raise FailedAliasError.new(
            "Tried to alias #{old_name} to #{new_name}, but" +
            " no method #{old_name} exists.", node)
        end
      end
      
      # On assignment: ensure bindings exist for all vars on the LHS
      add :assign, :massign do |node, names, vals|
        assgn_expression = AssignmentExpression.new(node)
        bind_variable_names(assgn_expression.lhs.names)
        attach_comment_annotations(assgn_expression.lhs.names, node.comment)
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
        attach_comment_annotations(lhs.names, node.comment)
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
        with_scope new_scope do
          attach_comment_annotations(arglist.map(&:name), node.comment)
        end
        visit_with_scope(argnode, new_scope) if argnode
        visit_with_scope(body, new_scope)
      end
      
      def attach_comment_annotations(names, comment)
        if comment && comment.annotation_map
          attach_type_annotations(names, comment.annotation_map)
        end
      end
      
      def attach_type_annotations(names, annotation_map)
        names.select { |name| annotation_map[name] }.each do |name|
          binding = @current_scope.lookup name
          binding.annotated_type = annotation_map[name].type
        end
      end
      
      # Eval handlers!
      match_precise_loadtime_method(proc { [ClassRegistry['Kernel'].instance_methods['require']] }) do |node, args|
        if args.is_constant?
          file = args.constant_values.first
          load_path = @current_scope.lookup('$:').value
          loaded_values = @current_scope.lookup('$"').value
          to_load = file + '.rb'
          load_path.each do |path|
            joined = File.join(path, to_load)
            if File.exist?(joined)
              if !loaded_values.include?(joined)
                tree = Annotations.annotate_inputs([[joined, File.read(joined)]])
                node.errors.concat tree[0][1].all_errors
              end
              break
            end
          end
        end
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