module Laser
  module Analysis
    module ControlFlow
      # This class builds a control flow graph. The algorithm used is
      # derived from Robert Morgan's "Building an Optimizing Compiler".
      class GraphBuilder
        attr_reader :graph, :enter, :exit, :temporary_counter, :current_block, :sexp
        attr_reader :self_register
        
        def initialize(sexp, formals=[], scope=Scope::GlobalScope)
          @sexp = sexp
          @formals = formals
          @graph = @enter = @exit = nil
          @scope_stack = [scope]
          @self_stack = []
          @temporary_counter = 0
          @temporary_table = Hash.new do |hash, keys|
            @temporary_counter += 1
            hash[keys] = Bindings::TemporaryBinding.new("%t#{@temporary_counter}", nil)
          end
        end

        def build
          initialize_graph
          @current_node = @sexp
          @self_register = Bindings::TemporaryBinding.new('self', current_scope.self_ptr)
          build_prologue
          result = walk_node @sexp, value: true
          if @sexp.type == :program
            uncond_instruct @current_return
          else
            return_uncond_jump_instruct result
          end
          
          @graph.prune_totally_useless_blocks
          @graph
        end

        def current_namespace
          scope = current_scope
          scope = scope.parent if @scope_stack.size == 1 && @sexp.type != :program
          scope.lexical_target
        end
        
        def push_scope(scope)
          @scope_stack.push scope
        end

        def current_scope
          @scope_stack.last
        end

        def pop_scope
          @scope_stack.pop
        end
        
        def with_scope(scope)
          push_scope scope
          yield
        ensure
          pop_scope
        end
        
        def push_self(obj)
          copy_instruct(@self_register, obj)
          @self_stack.push obj
        end

        def current_self
          @self_stack.last
        end

        def pop_self
          @self_stack.pop
          copy_instruct(@self_register, current_self)
        end

        def with_self(namespace)
          push_self namespace
          yield
        ensure
          pop_self
        end

        def query_self
          call_instruct(ClassRegistry['Laser#Magic'].binding,
              :current_self, value: true, raise: false)
        end

        def reobserve_current_exception
          cur_exception = call_instruct(ClassRegistry['Laser#Magic'].binding,
              :current_exception, value: true, raise: false)
          copy_instruct(@exception_register, cur_exception)
        end
        
        def observe_just_raised_exception
          cur_exception = call_instruct(ClassRegistry['Laser#Magic'].binding,
              :get_just_raised_exception, value: true, raise: false)
          copy_instruct(@exception_register, cur_exception)
        end

        def build_exception_blocks
          @return_register = create_temporary('t#return_value')
          @graph.final_return    = create_temporary('t#final_return')
          @exception_register    = create_temporary('t#exception_value')
          @graph.final_exception = create_temporary('t#exit_exception')
          @current_return = create_block(ControlFlowGraph::RETURN_POSTDOMINATOR_NAME)
          @current_rescue = create_block(ControlFlowGraph::EXCEPTION_POSTDOMINATOR_NAME)
          @current_yield_fail = create_block(ControlFlowGraph::YIELD_POSTDOMINATOR_NAME)
          joined = create_block(ControlFlowGraph::FAILURE_POSTDOMINATOR_NAME)
          with_current_basic_block(@current_rescue) do
            uncond_instruct joined, flags: RGL::ControlFlowGraph::EDGE_ABNORMAL
          end
          with_current_basic_block(@current_yield_fail) do
            uncond_instruct joined, flags: RGL::ControlFlowGraph::EDGE_ABNORMAL
          end
          with_current_basic_block(joined) do
            copy_instruct(@graph.final_exception, @exception_register)
            add_instruction(:raise, @graph.final_exception)
            uncond_instruct @exit, flags: RGL::ControlFlowGraph::EDGE_ABNORMAL, jump_instruct: false
          end
          with_current_basic_block(@current_return) do
            copy_instruct(@graph.final_return, @return_register)
            add_instruction(:return, @graph.final_return)
            uncond_instruct @exit, jump_instruct: false
          end
        end

        def reset_visibility_stack
          initial = call_instruct(ClassRegistry['Array'].binding, :[], const_instruct(:private), value: true, raise: false)
          copy_instruct(Bootstrap::VISIBILITY_STACK, initial)
        end

        def build_prologue
          uncond_instruct create_block
          if @sexp.type == :program
            push_self(Scope::GlobalScope.self_ptr)
          else
            push_self(query_self)
          end
          reset_visibility_stack
          build_exception_blocks
          if @sexp.type != :program
            dynamic_context = ClosedScope.new(current_scope, current_self)
            @scope_stack = [dynamic_context]
            @block_arg = call_instruct(ClassRegistry['Laser#Magic'].binding,
                :current_block, value: true, raise: false)
            @block_arg.name = 't#current_block'
            @graph.block_register = @block_arg
            reobserve_current_exception
            build_formal_args(@formals, block_arg: @block_arg) unless @formals.empty?
          end
        end
        
        def formal_arg_range(start, size)
          call_instruct(ClassRegistry['Laser#Magic'].binding, :current_argument_range,
              start, size, value: true, raise: false)
        end
        
        def formal_arg_at(idx)
          call_instruct(ClassRegistry['Laser#Magic'].binding, :current_argument, idx,
              value: true, raise: false)
        end
        
        def copy_positionals(args)
          args.each_with_index do |pos, idx|
            copy_instruct(pos, formal_arg_at(const_instruct(idx)))
          end
        end
        
        def copy_positionals_with_offset(args, offset)
          args.each_with_index do |pos, idx|
            dynamic_idx = idx.zero? ? offset : call_instruct(const_instruct(idx), :+, offset,
                value: true, raise: false)
            copy_instruct(pos, formal_arg_at(dynamic_idx))
          end
        end
        
        def build_formal_args(formals, opts={})
          formals.each { |formal| current_scope.add_binding!(formal) }

          nb_formals = formals.last.is_block? ? formals[0..-2] : formals
          has_rest  = rest_arg = nb_formals.find(&:is_rest?)
          min_arity = nb_formals.count(&:is_positional?)
          optionals = nb_formals.select(&:is_optional?)
          num_optionals = optionals.size
          min_nonrest_arity = min_arity + num_optionals
          # zero dynamic args = easy and more efficient case
          if !rest_arg && optionals.empty?
            copy_positionals(nb_formals)
          else
            # pre-dynamic positionals
            cur_arity = call_instruct(ClassRegistry['Laser#Magic'].binding,
                :current_arity, value: true, raise: false)
            pre_dynamic_positional = nb_formals.take_while(&:is_positional?)
            num_pre_dynamics = pre_dynamic_positional.size
            copy_positionals(pre_dynamic_positional)
            # optional args
            previous_optional_block = nil
            optionals.each_with_index do |argument, index|
              max_arity_indicating_missing = const_instruct(index + min_arity)
              has_arg, no_arg = create_blocks 2
              if previous_optional_block
                with_current_basic_block(previous_optional_block) do
                  uncond_instruct no_arg
                end
              end
              cond_result = call_instruct(cur_arity, :<, max_arity_indicating_missing,
                                          value: true, raise: false)
              cond_instruct cond_result, no_arg, has_arg
              
              start_block no_arg
              arg_value = walk_node(argument.default_value_sexp, value: true)
              copy_instruct(argument, arg_value)
              previous_optional_block = @current_block
              
              start_block has_arg
              copy_instruct(argument, formal_arg_at(const_instruct(index + num_pre_dynamics)))
            end
            
            optionals_done = create_block
            # rest args
            if has_rest
              rest_start = const_instruct(num_pre_dynamics + num_optionals)
              rest_size = call_instruct(cur_arity, :-, const_instruct(min_nonrest_arity), value: true, raise: false)
              copy_instruct(rest_arg, formal_arg_range(rest_start, rest_size))
            end
            uncond_instruct optionals_done

            if previous_optional_block
              with_current_basic_block(previous_optional_block) do
                # at this point, if there was a rest arg, it's empty.
                if has_rest
                  empty_rest = call_instruct(ClassRegistry['Array'].binding, :[], value: true, raise: false)
                  copy_instruct(rest_arg, empty_rest)
                end
                uncond_instruct optionals_done
              end
            end
            start_block optionals_done

            # post-dynamic conditionals
            post_dynamic_positional = nb_formals[num_pre_dynamics..-1].select(&:is_positional?)
            post_dynamic_start = call_instruct(cur_arity, :-,
                const_instruct(post_dynamic_positional.size), value: true, raise: false)
            copy_positionals_with_offset(post_dynamic_positional, post_dynamic_start)
          end
          block_arg = formals.find(&:is_block?)
          if block_arg
            if opts[:block_arg]
              the_block = opts[:block_arg]
            else
              the_block = call_instruct(ClassRegistry['Laser#Magic'].binding,
                  :current_block, value: true, raise: false)
            end
            copy_instruct(block_arg, the_block)
          end
        end
        
        # Creates a new block that jumps to the given target upon completion.
        # Very useful for building branches.
        def build_block_with_jump(target = nil, name = nil)
          new_block = name ? create_block(name) : create_block
          with_current_basic_block(new_block) do
            yield
            uncond_instruct target if target
          end
          new_block
        end
        
        # yields with the current basic block set to the provided basic block.
        # useful for quickly adding an edge without directly touching the
        # graph object.
        def with_current_basic_block(basic_block)
          old_block, @current_block = @current_block, basic_block
          yield
        ensure
          @current_block = old_block
        end
        
        def with_current_node(node)
          old_node, @current_node = @current_node, node
          @current_node.scope = current_scope
          yield
        ensure
          @current_node = old_node
        end
        
        # Walks the node differently based on whether the value is needed.
        def walk_node(node, opts={})
          with_current_node(node) do
            case node.type
            when :bodystmt
              bodystmt_walk node
            when :class
              class_name, superclass, body = node.children
              class_instruct(class_name, superclass, body, opts)
            when :module
              module_name, body = node.children
              module_instruct(module_name, body, opts)
            when :sclass
              receiver, body = node.children
              singleton_class_instruct receiver, body, opts
            when :def
              name, args, body = node.children
              name = const_instruct(name.expanded_identifier.to_sym)
              parsed_args = Signature.arg_list_for_arglist(args)
              def_opts =  opts.merge(line_number: node.line_number)
              def_instruct(current_namespace, name, parsed_args, body, def_opts)
            when :defs
              recv, _, name, args, body = node.children
              name = const_instruct(name.expanded_identifier.to_sym)
              receiver = walk_node(recv, value: true)
              singleton = call_instruct(receiver, :singleton_class, value: true)
              parsed_args = Signature.arg_list_for_arglist(args)
              def_opts =  opts.merge(line_number: node.line_number)
              def_instruct(singleton, name, parsed_args, body, def_opts)
            when :alias
              lhs, rhs = node.children
              lhs_val = const_instruct(lhs[1].expanded_identifier.to_sym)
              rhs_val = const_instruct(rhs[1].expanded_identifier.to_sym)
              call_instruct(current_namespace, :alias_method, lhs_val, rhs_val,
                            value: false, ignore_privacy: true)
            when :undef
              undeffed = node.children.first
              undeffed.each do |method|
                method_name = const_instruct(method[1].expanded_identifier.to_sym)
                call_instruct(current_namespace, :undef_method, method_name,
                    value: false, raise: true)
              end
              nil
            when :assign
              lhs, rhs = node.children
              single_assign_instruct(lhs, rhs, opts)
            when :massign
              lhs, rhs = node.children
              multiple_assign_instruct(lhs, rhs, opts)
            when :begin
              walk_node node[1], opts
            when :paren
              walk_body node[1], opts
            when :while
              condition, body = node.children
              while_instruct(condition, body, opts)
            when :while_mod
              condition, body_stmt = node.children
              while_instruct(condition, [body_stmt], opts)
            when :until
              condition, body = node.children
              until_instruct(condition, body, opts)
            when :until_mod
              condition, body_stmt = node.children
              until_instruct(condition, [body_stmt], opts)
            when :if
              if_instruct(node, false, opts)
            when :unless
              condition, body, else_block = node.children
              unless_instruct(condition, body, else_block, opts)
            when :if_mod
              if_instruct(node, true, opts)
            when :unless_mod
              condition, body = node.children
              unless_instruct(condition, [body], nil, opts)
            when :rescue_mod
              rescue_expr, guarded_expr = node.children
              rescue_mod_instruct(rescue_expr, guarded_expr, opts)
            when :unary
              op, receiver = node.children
              receiver = walk_node(receiver, value: true)
              call_instruct(receiver, op, opts)
            when :binary
              # If someone makes an overloaded operator that mutates something....
              # we have to run it (maybe), even if we hate them.
              lhs, op, rhs = node.children
              binary_instruct(lhs, op, rhs, opts)
            when :ifop
              cond, if_true, if_false = node.children
              ternary_instruct(cond, if_true, if_false, opts)
            when :const_path_ref
              lhs, const = node.children
              lhs_value = walk_node lhs, value: true
              ident = const_instruct(const.expanded_identifier)
              call_instruct(lhs_value, :const_get, ident, opts)
            when :call, :command, :command_call, :aref, :method_add_arg, :vcall
              issue_call node, opts
            when :method_add_block
              # need: the receiver, the method name, the arguments, and the block body
              method_call = node.method_call
              receiver = if method_call.receiver_node
                         then walk_node(method_call.receiver_node, value: true)
                         else self_instruct
                         end
              arg_node = method_call.arg_node
              arg_node = arg_node[1] if arg_node && arg_node.type == :arg_paren
              block_arg_bindings = node[2][1] ? Signature.arg_list_for_arglist(node[2][1][1]) : []
              body_sexp = node[2][2]
              case node[1].type
              when :super
                arg_node = arg_node[1] if arg_node.type == :args_add_block
                call_method_with_block(
                    receiver, method_call.method_name, arg_node,
                    block_arg_bindings, body_sexp, opts)
              when :zsuper
                call_zsuper_with_block(node[1], block_arg_bindings, body_sexp, opts)
              else
                opts = opts.merge(ignore_privacy: true) if method_call.implicit_receiver?
                call_method_with_block(
                    receiver, method_call.method_name, arg_node, block_arg_bindings, body_sexp, opts)
              end
            when :super
              issue_super_call(node)
            when :zsuper
              # TODO(adgar): blocks in args & style
              block = rb_check_convert_type(@block_arg, ClassRegistry['Proc'].binding, :to_proc)
              invoke_super_with_block(*compute_zsuper_arguments, block, opts)
            when :yield
              yield_instruct(node[1], opts)
            when :yield0
              yield_instruct(nil, opts)
            when :return
              return_instruct node
              const_instruct(nil) if opts[:value]
            when :return0
              return0_instruct
              const_instruct(nil) if opts[:value]
            when :break
              break_instruct(node[1])
              const_instruct(nil) if opts[:value]
            when :next
              next_instruct(node[1])
              const_instruct(nil) if opts[:value]
            when :redo
              redo_instruct
              const_instruct(nil) if opts[:value]
            when :void_stmt
              const_instruct(nil) if opts[:value]
            when :program
              uncond_instruct create_block
              walk_body node[1], value: false
            when :dot3
              start, stop = node.children
              start_val = walk_node(start, value: true)
              stop_val = walk_node(stop, value: true)
              true_val = const_instruct(true)
              call_instruct(ClassRegistry['Range'].binding, :new, start_val, stop_val, true_val, opts)
            when :dot2
              start, stop = node.children
              start_val = walk_node(start, value: true)
              stop_val = walk_node(stop, value: true)
              false_val = const_instruct(false)
              call_instruct(ClassRegistry['Range'].binding, :new, start_val, stop_val, false_val, opts)
            else
              opts[:value] ? value_walk(node) : novalue_walk(node)
            end
          end
        end
        
        # Walks the node expecting that the expression's return value will be discarded.
        # Since everything is an expression in Ruby, knowing when to ignore return
        # values is nice.
        def novalue_walk(node)
          with_current_node(node) do
            case node.type
            when :void_stmt
              # Do nothing.
            when :massign
              lhs, rhs = node.children
              multiple_assign_instruct(lhs, rhs, value: false)
            when :opassign
              lhs, op, rhs = node.children
              op = op.expanded_identifier[0..-2].to_sym
              if lhs.type == :field
                receiver = walk_node lhs[1], value: true
                method_name = lhs[3].expanded_identifier
                # Receiver is ONLY EVALUATED ONCE
                # (on ruby 1.9.2p136 (2010-12-25 revision 30365) [x86_64-darwin10.6.0])
                current_val = call_instruct(receiver, method_name.to_sym, block: false, value: true)
                if op == :"||"
                  false_block, after = create_blocks 2
                  cond_instruct(current_val, after, false_block)

                  start_block false_block
                  rhs_value = walk_node rhs, value: true
                  call_instruct(receiver, "#{method_name}=".to_sym, rhs_value, block: false, value: false)
                  uncond_instruct after
                
                  start_block after
                elsif op == :"&&"
                  true_block, after = create_blocks 2
                  cond_instruct(current_val, true_block, after)

                  start_block true_block
                  rhs_value = walk_node rhs, value: true
                  call_instruct(receiver, "#{method_name}=".to_sym, rhs_value, block: false, value: false)
                  uncond_instruct after
                
                  start_block after
                else
                  rhs_value = walk_node rhs, value: true
                  temp_result = call_instruct(current_val, op, rhs_value, block: false, value: true)
                  call_instruct(receiver, "#{method_name}=".to_sym, temp_result, block: false, value: false)
                end
              # TODO(adgar): aref_field
              else
                result = binary_instruct(lhs, op, rhs, value: true)
                single_assign_instruct(lhs, result)
              end
            when :case
              after = create_block
              argument, body = node.children
              argument_value = walk_node argument, value: true
            
              while body && body.type == :when
                when_opts, when_body, body = body.children
                when_body_block = create_block
                when_opts.each do |opt|
                  after_fail = create_block
                  condition_result = call_instruct(walk_node(opt, value: true), :===, argument_value, value: true)
                  cond_instruct(condition_result, when_body_block, after_fail)
                  start_block after_fail
                end
                all_fail = @current_block

                start_block when_body_block
                walk_body when_body, value: false
                uncond_instruct after
              
                start_block all_fail
              end
              if body && body.type == :else
                walk_body body[1], value: false
              end
              uncond_instruct after
            when :var_ref
              nil
            when :for
              lhs, receiver, body = node.children
              receiver_value = walk_node receiver, value: true
              if Symbol === lhs[0]
                # field or var_ref/const_ref
                case lhs.type
                when :field
                  # TODO(adgar): generate calls
                else
                  # just get the value
                  arg_bindings = [lhs.binding]
                  call_method_with_block(receiver_value, :each, [], arg_bindings, body, value: false)
                end
              else
                # TODO(adgar): multiple assign
              end
            when :string_embexpr
              node[1].each { |elt| walk_node(elt, value: false) }
            when :@CHAR, :@tstring_content, :@int, :@float, :@regexp_end, :symbol,
                 :@label, :symbol_literal, :defined
              # do nothing
            when :string_literal
              content_nodes = node[1].children
              content_nodes.each do |node|
                walk_node node, value: false
              end
            when :xstring_literal
              body = build_string_instruct(node[1])
              call_instruct(self_register, :`, body, value: false)
            when :regexp_literal
              node[1].each { |part| walk_node node, value: false }
            when :dyna_symbol
              content_nodes = node[1].children
              content_nodes.each { |node| walk_node node, value: false }
            when :array
              receiver = ClassRegistry['Array'].binding
              generic_call_instruct(receiver, :[], node[1], false, value: false)
            when :hash
              if node[1]
                walk_node node[1], value: false
              else
                const_instruct({}, value: false)
              end
            when :assoclist_from_args, :bare_assoc_hash
              pairs = node[1]
              key_value_paired = pairs.map {|a, b| [walk_node(a, value: true), walk_node(b, value: true)] }.flatten
              receiver = ClassRegistry['Hash'].binding
              call_instruct(receiver, :[], *key_value_paired, block: false, value: false, raise: false)
            else
              raise ArgumentError.new("Unknown AST node type #{node.type.inspect}")
            end
          end
        end
        
        # Walks the node with the expectation that the return value will be used.
        def value_walk(node)
          with_current_node(node) do
            case node.type
            when :opassign
              lhs, op, rhs = node.children
              op = op.expanded_identifier[0..-2].to_sym
              if lhs.type == :field
                receiver = walk_node lhs[1], value: true
                method_name = lhs[3].expanded_identifier
                # Receiver is ONLY EVALUATED ONCE
                # (on ruby 1.9.2p136 (2010-12-25 revision 30365) [x86_64-darwin10.6.0])
                current_val = call_instruct(receiver, method_name.to_sym, block: false, value: true)
                if op == :"||"
                  result = create_temporary
                  true_block, false_block, after = create_blocks 3
                  cond_instruct(current_val, true_block, false_block)

                  start_block true_block
                  copy_instruct result, current_val
                  uncond_instruct after

                  start_block false_block
                  rhs_value = walk_node rhs, value: true
                  call_instruct(receiver, "#{method_name}=".to_sym, rhs_value, block: false, value: false)
                  copy_instruct result, rhs_value
                  uncond_instruct after
                
                  start_block after
                  result
                elsif op == :"&&"
                  result = create_temporary
                  true_block, false_block, after = create_blocks 3
                  cond_instruct(current_val, true_block, false_block)

                  start_block true_block
                  rhs_value = walk_node rhs, value: true
                  call_instruct(receiver, "#{method_name}=".to_sym, rhs_value, block: false, value: false)
                  copy_instruct result, rhs_value
                  uncond_instruct after

                  start_block false_block
                  copy_instruct result, current_val
                  uncond_instruct after
                
                  start_block after
                  result
                else
                  rhs_value = walk_node rhs, value: true
                  temp_result = call_instruct(current_val, op, rhs_value, block: false, value: true)
                  call_instruct(receiver, "#{method_name}=".to_sym, temp_result, block: false, value: false)
                  temp_result
                end
              # TODO(adgar): aref_field
              else
                result = binary_instruct(lhs, op, rhs, value: true)
                single_assign_instruct(lhs, result)
                result
              end
            when :var_field
              variable_instruct(node)
            when :var_ref
              if node[1].type == :@const
                const_lookup(node[1].expanded_identifier)
              elsif node[1].type == :@ident || node[1].expanded_identifier == 'self'
                variable_instruct(node)
              elsif node[1].type == :@kw
                const_instruct(node.constant_value)
              elsif node[1].type == :@ivar
                call_instruct(current_self, :instance_variable_get,
                    const_instruct(node.expanded_identifier), value: true, ignore_privacy: true)
              elsif node[1].type == :@gvar
                call_instruct(ClassRegistry['Laser#Magic'].binding, :get_global,
                    const_instruct(node.expanded_identifier), raise: false, value: true)
              end
            when :top_const_ref
              const = node[1]
              ident = const_instruct(const.expanded_identifier)
              call_instruct(ClassRegistry['Object'].binding,
                  :const_get, ident, value: true)
            when :for
              lhs, receiver, body = node.children
              receiver_value = walk_node receiver, value: true
              if Symbol === lhs[0]
                # field or var_ref/const_ref
                case lhs.type
                when :field
                  # call
                else
                  # just get the value
                  arg_bindings = [lhs.binding]
                  call_method_with_block(receiver_value, :each, [], arg_bindings, body, value: true)
                end
              # TODO(adgar): aref_field
              else
                # TODO(adgar): multiple assign
              end
            when :case
              after = create_block
              result = create_temporary
              argument, body = node.children
              argument_value = walk_node argument, value: true
            
              while body && body.type == :when
                when_opts, when_body, body = body.children
                when_body_block = create_block
                when_opts.each do |opt|
                  after_fail = create_block
                  condition_result = call_instruct(walk_node(opt, value: true), :===, argument_value, value: true)
                  cond_instruct(condition_result, when_body_block, after_fail)
                  start_block after_fail
                end
                all_fail = @current_block

                start_block when_body_block
                when_body_result = walk_body when_body, value: true
                copy_instruct(result, when_body_result)
                uncond_instruct after
              
                start_block all_fail
              end
              if body.nil?
                copy_instruct(result, nil)
                uncond_instruct after
              elsif body.type == :else
                else_body_result = walk_body body[1], value: true
                copy_instruct(result, else_body_result)
                uncond_instruct after
              end
              
              start_block after
              result
            when :@CHAR, :@tstring_content, :@int, :@float, :@regexp_end, :symbol,
                 :@label, :symbol_literal
              const_instruct(node.constant_value)
            when :string_literal
              content_nodes = node[1].children
              build_string_instruct(content_nodes)
            when :string_embexpr
              final = walk_body node[1], value: true
              call_instruct(final, :to_s, value: true)
            when :xstring_literal
              body = build_string_instruct(node[1])
              call_instruct(self_register, :`, body, value: true)
            when :regexp_literal
              body = build_string_instruct(node[1])
              options = const_instruct(node[2].constant_value)
              receiver = ClassRegistry['Regexp'].binding
              call_instruct(receiver, :new, body, options, value: true)
            when :dyna_symbol
              content_nodes = node[1].children
              string_version = build_string_instruct(content_nodes)
              call_instruct(string_version, :to_sym, value: true, raise: false)
            when :array
              receiver = ClassRegistry['Array'].binding
              generic_call_instruct(receiver, :[], node[1], false, value: true)
            when :hash
              if node[1]
                walk_node node[1], value: true
              else
                const_instruct({})
              end
            when :assoclist_from_args, :bare_assoc_hash
              pairs = node[1].map { |_, k, v| [k, v] }
              key_value_paired = pairs.map {|a, b| [walk_node(a, value: true), walk_node(b, value: true)] }.flatten
              receiver = ClassRegistry['Hash'].binding
              call_instruct(receiver, :[], *key_value_paired, block: false, value: true)
            when :defined
              defined_op_instruct(node[1])
            else
              raise ArgumentError.new("Unknown AST node type #{node.type.inspect}")
            end
          end
        end
        
       private

        def initialize_graph
          @graph = ControlFlowGraph.new(@formals)
          @graph.root = @sexp
          @block_counter = 0
          @enter = @graph.enter
          @exit = @graph.exit
          @temporary_counter = 0
          @current_break = @current_next = @current_redo = @current_return = @current_rescue = nil
          start_block @enter
        end
        
        # Redirects break, next, redo, and return to the given Sexp for each
        # target to redirect.
        def with_jumps_redirected(targets={})
          new_targets = targets.merge(targets) do |key, redirect|
            current = send("current_#{key}")
            next nil unless current
            build_block_with_jump(current) do
              walk_body redirect, value: false
            end
          end.delete_if { |k, v| v.nil? }
          with_jump_targets(new_targets) do
            yield
          end
        end
        
        # Yields with jump targets specified. Since a number of jump targets
        # require temporary specification in a stack-like fashion during CFG construction,
        # I use the call stack to simulate the explicit one suggested by Morgan.
        def with_jump_targets(targets={})
          old_break, old_next, old_redo, old_return, old_rescue, old_yield_fail =
              @current_break, @current_next, @current_redo, @current_return, @current_rescue, @current_yield_fail
          @current_break = targets[:break] if targets.has_key?(:break)
          @current_next = targets[:next] if targets.has_key?(:next)
          @current_redo = targets[:redo] if targets.has_key?(:redo)
          @current_return = targets[:return] if targets.has_key?(:return)
          @current_rescue = targets[:rescue] if targets.has_key?(:rescue)
          @current_yield_fail = targets[:yield_fail] if targets.has_key?(:yield_fail)
          yield
        ensure
          @current_break, @current_next, @current_redo, @current_return, @current_rescue, @current_yield_fail =
              old_break, old_next, old_redo, old_return, old_rescue, old_yield_fail
        end
        
        # Walks over a series of statements, ignoring the return value of
        # everything except the last statement. Stores the result of the
        # last statement in the result parameter.
        def walk_body(body, opts={})
          opts = {value: true}.merge(opts)
          if opts[:value]
            body[0..-2].each { |elt| walk_node(elt, value: false) }
            if body.any?
              walk_node(body.last, value: true)
            else
              const_instruct(nil)
            end
          else
            body.each { |node| walk_node node, value: false }
          end
        end
        
        def raise_instruct(arg, opts)
          target = opts[:target]
          call_instruct(ClassRegistry['Laser#Magic'].binding, :push_exception, arg, raise: false)
          copy_instruct(@exception_register, arg)
          uncond_instruct target, flags: RGL::ControlFlowGraph::EDGE_ABNORMAL
          start_block target
        end
        
        def raise_instance_of_instruct(klass, *args)
          opts = {target: current_rescue}
          opts.merge!(args.pop) if Hash === args.last
          instance = call_instruct(klass, :new, *args, value: true, raise: false)
          raise_instruct instance, opts
        end
        
        # Yields with an explicit block being wrapped around the execution of the
        # user's block. The basic block object created is provided as a parameter to the
        # caller's operations which have the possibility of invoking the block.
        def call_with_explicit_block(block_arg_bindings, block_sexp)
          body_block = create_block
          body_value, body_proc = create_block_temporary block_arg_bindings, block_sexp, @current_block
          call_instruct(body_value, :lexical_self=, self_instruct, raise: false, value: false)
          @graph.add_edge(@current_block, body_block,
              ControlFlowGraph::EDGE_BLOCK_TAKEN | ControlFlowGraph::EDGE_ABNORMAL)
          result = yield(body_value)
          after = @current_block  # new block caused by method call
          block_exit = build_block_exit_block body_block, after
          body_proc.exit_block = block_exit
          walk_block_body block_arg_bindings, body_block, block_exit, block_sexp, after
          start_block after
          result
        end
        
        def build_block_exit_block(body_block, after)
          build_block_with_jump(nil, body_block.name + '-Exit') do
            @graph.add_edge(@current_block, body_block,
                RGL::ControlFlowGraph::EDGE_ABNORMAL | RGL::ControlFlowGraph::EDGE_BLOCK_TAKEN)
            @graph.add_edge(@current_block, after)
            add_potential_raise_edge(false)
          end
        end

        def call_zsuper_with_block(node, block_arg_bindings, block_sexp, opts={})
          opts = {value: true, raise: true}.merge(opts)
          call_with_explicit_block(block_arg_bindings, block_sexp) do |body_value|
            invoke_super_with_block *compute_zsuper_arguments, body_value, opts
          end
        end

        def call_method_with_block(receiver, method, args, block_arg_bindings, block_sexp, opts={})
          opts = {value: true, raise: true}.merge(opts)
          call_with_explicit_block(block_arg_bindings, block_sexp) do |body_value|
            generic_call_instruct receiver, method, args, body_value, opts
          end
        end
        
        def invoke_super_with_block(args, is_vararg, body_block, opts={})
          opts = {value: true, raise: true}.merge(opts)
          # TODO(adgar): blocks in args & style
          if is_vararg
          then super_vararg_instruct(args, {block: body_block}.merge(opts))
          else super_instruct(*args, {block: body_block}.merge(opts))
          end
        end
        
        # Walks the block with it's new next/etc. boundaries set based on the block's
        # scope
        def walk_block_body(block_arg_bindings, body_block, block_exit, body, after)
          block_exception = create_temporary(body_block.name + '_final_exception')
          rescue_block = build_block_with_jump(nil, body_block.name + '-Failure') do
            copy_instruct(block_exception, @exception_register)
            add_instruction(:raise, block_exception)
            uncond_instruct block_exit, flags: RGL::ControlFlowGraph::EDGE_ABNORMAL, jump_instruct: false
          end
          with_jump_targets(rescue: rescue_block) do
            with_current_basic_block(body_block) do
              body_result = nil
              with_self(query_self) do
                build_formal_args(block_arg_bindings)
                body_result = walk_body body, value: true
              end
              add_instruction(:return, body_result)
              uncond_instruct(block_exit, jump_instruct: false)
            end
          end
        end

        # Terminates the current block with a jump to the target block.
        def uncond_instruct(target, opts = {})
          opts = {jump_instruct: true, flags: RGL::ControlFlowGraph::EDGE_NORMAL}.merge(opts)
          add_instruction(:jump, target.name) if opts[:jump_instruct]
          @graph.add_edge(@current_block, target, opts[:flags])
          start_block target
        end
        
        # Creates an unconditional branch from the current block, based on the given
        # value, to either the true block or the false block.
        def cond_instruct(val, true_block, false_block, opts = {branch_instruct: true})
          if opts[:branch_instruct]
            add_instruction(:branch, val, true_block.name, false_block.name)
          end
          @graph.add_edge(@current_block, true_block)
          @graph.add_edge(@current_block, false_block)
        end
        
        # Performs a no-arg return.
        def return0_instruct
          return_uncond_jump_instruct(nil)
        end
        
        def return_instruct(node)
          result = evaluate_args_into_array node[1]
          return_uncond_jump_instruct result
        end
        
        def return_uncond_jump_instruct(result)
          copy_instruct(@return_register, result)
          uncond_instruct @current_return
          start_block create_block
          result
        end
        
        # Performs a yield of the given value, capturing the return
        # value.
        def yield_instruct(arg_node, opts={})
          opts = {raise: true, value: true}.merge(opts)
          # this is: if @block_arg; @block_arg.call(args)
          #          else raise LocalJumpError.new(...)
          if_block, no_block = create_blocks 2
          cond_instruct(@block_arg, if_block, no_block)
          
          start_block no_block
          message = const_instruct('no block given (yield)')
          raise_instance_of_instruct(
              ClassRegistry['LocalJumpError'].binding, message,
              target: current_yield_fail)
          
          start_block if_block
          if arg_node.nil?
            result = call_instruct(@block_arg, :call, opts)
          else
            arg_node = arg_node[1] if arg_node[0] == :paren
            result = generic_call_instruct(@block_arg, :call, arg_node[1], nil, opts)
          end
          result
        end

        def yield_instruct_with_arg(node, opts={})
          opts = {raise: true, value: true}.merge(opts)
          result = evaluate_args_into_array node[1]
          yield_instruct result, opts
        end

        # Takes an argument node and evaluates it into an array. used by
        # return and yield, as they always pass along 1 argument.
        def evaluate_args_into_array(args)
          if args[0] == :args_add_star
            # if there's a splat, always return an actual array object of all the arguments.
            compute_varargs(args)
          elsif args[0] == :paren
            evaluate_args_into_array(args[1])
          elsif args[0] == :args_add_block
            evaluate_args_into_array(args[1])
          elsif args.size > 1
            # if there's more than 1 argument, but no splats, then we just pack
            # them into an array and return that array.
            arg_temps = args.map { |arg| walk_node arg, value: true }
            result = call_instruct(ClassRegistry['Array'].binding, :[], *arg_temps,
                                   value: true, raise: false)
          else
            # Otherwise, just 1 simple argument: return it.
            walk_node args[0], value: true
          end
        end
        
        attr_reader :current_break, :current_next, :current_redo
        attr_reader :current_return, :current_rescue, :current_yield_fail        
        
        # TODO(adgar): ARGUMENTS
        def break_instruct(args)
          uncond_instruct @current_break
          start_block create_block
        end
        
        # TODO(adgar): ARGUMENTS
        def next_instruct(args)
          uncond_instruct @current_next
          start_block create_block
        end

        def redo_instruct
          add_fake_edge @current_block, @graph.exit
          uncond_instruct @current_redo
          start_block create_block
          add_fake_edge @graph.enter, @current_block
        end

        # Walks a body statement.
        def bodystmt_walk(node)
          # Pretty fucking compact encapsulation of the :bodystmt block. Damn, mother
          # fucker.
          result = create_temporary

          body, rescue_body, else_body, ensure_body = node.children
          body_block, after = create_blocks 2
          uncond_instruct body_block

          if ensure_body
            ensure_block = create_block

            # Generate the body with redirects to the ensure block, so no jumps get away without
            # running the ensure block
            with_jumps_redirected(break: ensure_body[1], redo: ensure_body[1], next: ensure_body[1],
                                  return: ensure_body[1], rescue: ensure_body[1],
                                  yield_fail: ensure_body[1]) do
              rescue_target, yield_fail_target =
                  build_rescue_target(node, result, rescue_body, ensure_block,
                                      current_rescue, current_yield_fail)
              walk_body_with_rescue_target(result, body, body_block, rescue_target, yield_fail_target)
            end
            uncond_instruct ensure_block
            walk_body(ensure_body[1], value: false)
            uncond_instruct after
          else
            # Generate the body with redirects to the ensure block, so no jumps get away without
            # running the ensure block
            rescue_target, yield_fail_target =
                build_rescue_target(node, result, rescue_body, after,
                                    current_rescue, current_yield_fail)
            walk_body_with_rescue_target(result, body, body_block, rescue_target, yield_fail_target)
            uncond_instruct after
          end
          result
        end

        # Builds the rescue block(s) for the given rescue_body, if there is one,
        # and returns the block to jump to when an exception is raised.
        def build_rescue_target(node, result, rescue_body, destination, rescue_fail, yield_fail_target)
          if rescue_body
          then rescue_instruct(node, result, rescue_body, destination, rescue_fail, yield_fail_target)
          else [rescue_fail, yield_fail_target]
          end
        end

        # Walks the body of code with its result copied and its rescue target set.
        def walk_body_with_rescue_target(result, body, body_block, rescue_target, yield_fail_target)
          with_jump_targets(rescue: rescue_target, yield_fail: yield_fail_target) do
            start_block body_block
            body_result = walk_body body, value: true
            copy_instruct(result, body_result)
          end
        end

        def rescue_instruct(node, enclosing_body_result, rescue_body, ensure_block, rescue_fail, yield_fail)
          rescue_target, yield_fail_target = create_blocks 2
          catchers = [rescue_target, yield_fail_target]
          start_block rescue_target
          while rescue_body
            rhs, exception_name, handler_body, rescue_body = rescue_body.children
            rhs ||= Sexp.new([[:var_ref, [:@const, 'StandardError', [0, 0]]]])
            handler_block = create_block

            # for everything in rescue_body[1]
            # check if === $!, if so, go to handler_block, if not, keep checking.
            catchers.map! do |catcher|
              with_current_basic_block(catcher) do
                failure_block = nil
                foreach_on_rhs(rhs) do |temp|
                  result = call_instruct(temp, :===, @exception_register, value: true)
                  failure_block = create_block
                  cond_instruct(result, handler_block, failure_block)
                  start_block failure_block
                end
                @current_block
              end
            end
            
            # Build the handler block.
            start_block handler_block
            # Assign to $! if there is a requested name for the exception
            if exception_name
              var_name = exception_name.expanded_identifier
              copy_instruct(current_scope.lookup_or_create_local(var_name), @exception_register)
            end
            body_result = walk_body handler_body, value: true
            copy_instruct(enclosing_body_result, body_result)
            call_instruct(ClassRegistry['Laser#Magic'].binding, :pop_exception, raise: false)
            uncond_instruct ensure_block
          end
          # All rescues failed.
          else_body = node[3]
          rescue_else_instruct(else_body, catchers, [rescue_fail, yield_fail])  # else_body
          [rescue_target, yield_fail_target]
        end
        
        # Builds a rescue-else body.
        def rescue_else_instruct(else_body, catchers, fail_targets)
          catchers.zip(fail_targets).each do |catcher, fail_target|
            with_current_basic_block(catcher) do
              if else_body
                else_block = create_block
                uncond_instruct else_block
                start_block else_block
                walk_body else_body[1], value: false
              end
              uncond_instruct fail_target, flags: RGL::ControlFlowGraph::EDGE_ABNORMAL
            end
          end
        end

        # Generates the code for the 'expr rescue expr' construct, which
        # catches StandardError exceptions. Offers a nice optimization opportunity
        # for yield-failure.
        def rescue_mod_instruct(guarded_expr, rescue_expr, opts={value: true})
          # first off, yield failure ALWAYS caught, so that's optimized
          # no ensure, else, etc
          # StandardError is the caught exception
          result_temporary = create_temporary if opts[:value]
          rescue_check_block, after = create_blocks 2
          is_caught_block = build_block_with_jump(after) do
            caught_result = walk_node(rescue_expr, opts)
            copy_instruct(result_temporary, caught_result) if opts[:value]
          end
          with_current_basic_block(rescue_check_block) do
            caught = call_instruct(ClassRegistry['StandardError'].binding, :===,
                                   @exception_register, value: true, raise: false)
            cond_instruct(caught, is_caught_block, current_rescue)
          end
          with_jump_targets(rescue: rescue_check_block, yield_fail: is_caught_block) do
            normal_result = walk_node(guarded_expr, opts)
            copy_instruct(result_temporary, normal_result) if opts[:value]
            uncond_instruct(after)
          end
          result_temporary
        end

        def class_instruct(class_name, superclass, body, opts={value: true})
          # first: calculate receiver to perform a check if
          # the class already exists
          the_class_holder = create_temporary
          case class_name.type
          when :const_ref
            receiver_val = current_namespace
            name_as_string = class_name.expanded_identifier
          when :const_path_ref
            receiver_val = walk_node(class_name[1], value: true)
            name_as_string = class_name[2].expanded_identifier
          when :top_const_ref
            receiver_val = ClassRegistry['Object'].binding
            name_as_string = class_name[1].expanded_identifier
          end
          actual_name = const_instruct(name_as_string)

          if superclass
            superclass_val = walk_node(superclass, value: true)
            need_confirm_superclass = true
          else
            superclass_val = lookup_or_create_temporary(:var, '::Object')
            copy_instruct(superclass_val, ClassRegistry['Object'])
            need_confirm_superclass = false
          end
          
          already_exists = call_instruct(receiver_val, :const_defined?, actual_name, const_instruct(false), value: true, raise: false)
          if_exists_block, if_noexists_block, after_exists_check = create_blocks 3
          cond_instruct(already_exists, if_exists_block, if_noexists_block)
          
          ############### LOOKING UP AND VERIFYING CLASS BRANCH ###########
          
          start_block if_exists_block
          the_class = call_instruct(receiver_val, :const_get, actual_name, const_instruct(false), value: true, raise: false)
          copy_instruct(the_class_holder, the_class)
          # check if it's actually a module
          is_module_block, after_conflict_check = create_blocks 2
          is_class_cond_val = call_instruct(ClassRegistry['Class'].binding, :===, the_class, value: true, raise: false)
          cond_instruct(is_class_cond_val, after_conflict_check, is_module_block)
          
          # Unconditionally raise if it is not a class! The error is a TypeError
          start_block is_module_block
          raise_instance_of_instruct(ClassRegistry['LaserReopenedModuleAsClassError'].binding,
              const_instruct("#{name_as_string} is not a class"))
          
          start_block after_conflict_check
          # Now, compare superclasses if provided superclass is not Object
          if need_confirm_superclass
            should_not_confirm_superclass = call_instruct(superclass_val, :equal?,
                ClassRegistry['Object'].binding, value: true, raise: false)
            validate_superclass_mismatch_block = create_block
            cond_instruct(should_not_confirm_superclass, after_exists_check, validate_superclass_mismatch_block)

            start_block validate_superclass_mismatch_block
            old_superclass_val = call_instruct(the_class, :superclass, value: true, raise: false)
            superclass_is_equal_cond = call_instruct(old_superclass_val, :equal?, superclass_val, value: true, raise: false)
            superclass_conflict_block = create_block
            cond_instruct(superclass_is_equal_cond, after_exists_check, superclass_conflict_block)
            
            start_block superclass_conflict_block
            raise_instance_of_instruct(ClassRegistry['LaserSuperclassMismatchError'].binding,
                const_instruct("superclass mismatch for class #{name_as_string}"))
          else
            uncond_instruct(after_exists_check)
          end
          
          ############### CREATING CLASS BRANCH ###############################
          
          start_block if_noexists_block
          # only confirm superclass if it's not defaulting to Object!
          if need_confirm_superclass
            is_not_class_block, after_is_class_check = create_blocks 2
            is_class_cond_val = call_instruct(ClassRegistry['Class'].binding, :===, superclass_val, value: true, raise: false)
            cond_instruct(is_class_cond_val, after_is_class_check, is_not_class_block)
          
            start_block is_not_class_block
            raise_instance_of_instruct ClassRegistry['TypeError'].binding
          
            start_block after_is_class_check
          end
          # create the class and assign
          the_class = call_instruct(ClassRegistry['Class'].binding, :new, superclass_val, value: true, raise: false)
          call_instruct(receiver_val, :const_set, actual_name, the_class, value: false, raise: false)
          copy_instruct(the_class_holder, the_class)
          uncond_instruct after_exists_check

          start_block after_exists_check
          call_instruct(Bootstrap::VISIBILITY_STACK, :push, const_instruct(:public), raise: false, value: false)
          # use this namespace!
          module_eval_instruct(the_class_holder, body, opts)
          call_instruct(Bootstrap::VISIBILITY_STACK, :pop, raise: false, value: false)
        end
        
        def module_instruct(module_name, body, opts={value: true})
          # first: calculate receiver to perform a check if
          # the class already exists
          the_module_holder = create_temporary
          case module_name.type
          when :const_ref
            receiver_val = current_namespace
            name_as_string = module_name.expanded_identifier
          when :const_path_ref
            receiver_val = walk_node(module_name[1], value: true)
            name_as_string = module_name[2].expanded_identifier
          when :top_const_ref
            receiver_val = ClassRegistry['Object'].binding
            name_as_string = module_name[1].expanded_identifier
          end
          actual_name = const_instruct(name_as_string)

          already_exists = call_instruct(receiver_val, :const_defined?, actual_name, const_instruct(false), value: true, raise: false)
          if_exists_block, if_noexists_block, after_exists_check = create_blocks 3
          cond_instruct(already_exists, if_exists_block, if_noexists_block)

          start_block if_exists_block
          the_module = call_instruct(receiver_val, :const_get, actual_name, const_instruct(false), value: true, raise: false)
          copy_instruct(the_module_holder, the_module)
          # check if it's actually a class
          is_class_block, after_conflict_check = create_blocks 2
          is_class_cond_val = call_instruct(ClassRegistry['Class'].binding, :===, the_module, value: true, raise: false)
          cond_instruct(is_class_cond_val, is_class_block, after_exists_check)

          # Unconditionally raise if it is a class! The error is a TypeError
          start_block is_class_block
          raise_instance_of_instruct(ClassRegistry['LaserReopenedClassAsModuleError'].binding,
              const_instruct("#{name_as_string} is not a module"))

          start_block if_noexists_block
          # create the class and assign
          the_module = call_instruct(ClassRegistry['Module'].binding, :new, value: true, raise: false)
          call_instruct(receiver_val, :const_set, actual_name, the_module, value: false, raise: false)
          copy_instruct(the_module_holder, the_module)
          uncond_instruct after_exists_check

          start_block after_exists_check

          call_instruct(Bootstrap::VISIBILITY_STACK, :push, const_instruct(:public), raise: false, value: false)
          module_eval_instruct(the_module_holder, body, opts)
          call_instruct(Bootstrap::VISIBILITY_STACK, :pop, raise: false, value: false)
        end

        def singleton_class_instruct(receiver, body, opts={value: false})
          receiver_val = walk_node receiver, value: true

          maybe_symbol, no_singleton, has_singleton = create_blocks 3
          cond_result = call_instruct(ClassRegistry['Fixnum'].binding, :===, receiver_val, value: true)
          cond_instruct(cond_result, no_singleton, maybe_symbol)

          start_block maybe_symbol
          cond_result = call_instruct(ClassRegistry['Symbol'].binding, :===, receiver_val, value: true)
          cond_instruct(cond_result, no_singleton, has_singleton)
          
          start_block no_singleton
          raise_instance_of_instruct ClassRegistry['TypeError'].binding

          start_block has_singleton
          singleton = call_instruct(receiver_val, :singleton_class, value: true, raise: false)
          module_eval_instruct(singleton, body, opts)
        end

        def module_eval_instruct(new_self, body, opts)
          with_scope(ClosedScope.new(current_scope, new_self)) do
            with_self new_self do
              walk_node body, opts
            end
          end
        end

        # Defines a method on the current lexically-enclosing class/module.
        def def_instruct(receiver, name, args, body, opts = {})
          opts = {value: false}.merge(opts)
          body.scope = current_scope
          block, new_proc = create_block_temporary(args, body)
          new_proc.line_number = opts[:line_number]
          new_proc.annotations = body.parent.comment.annotation_map if body.parent.comment
          call_instruct(receiver, 'define_method', name, block, raise: false)
          const_instruct(nil) if opts[:value]
        end

        # Creates a temporary, assigns it a constant value, and returns it.
        def const_instruct(val)
          result = lookup_or_create_temporary(:const, val)
          copy_instruct result, val
          result
        end
        
        def self_instruct
          @self_register
        end
        
        # Copies one register to another.
        def copy_instruct(lhs, rhs)
          add_instruction(:assign, lhs, rhs)
        end
        
        def evaluate_if_needed(node, opts={})
          if Bindings::Base === node
            node
          else
            walk_node(node, opts)
          end
        end
        
        # Does a single assignment between an LHS node and an RHS node, both unevaluated.
        # This can be used by massign calls! In fact, it's very important to structure
        # this code to handle such cases.
        def single_assign_instruct(lhs, rhs, opts={})
          opts = {value: true}.merge(opts)
          case lhs.type
          when :field
            # In 1.9.2, receiver is evaulated first, then the arguments
            receiver = walk_node lhs[1], value: true
            method_name = lhs[3].expanded_identifier
            rhs_val = evaluate_if_needed(rhs, value: true)
            call_instruct(receiver, "#{method_name}=".to_sym, rhs_val, {block: false}.merge(opts))
            rhs_val
          when :aref_field
            generic_aref_instruct(walk_node(lhs[1], value: true), lhs[2][1], rhs, opts)
          when :const_path_field
            receiver, const = lhs.children
            receiver_val = walk_node(receiver, value: true)
            const_name_val = const_instruct(const.expanded_identifier)
            rhs_val = evaluate_if_needed(rhs, value: true)
            # never raises!
            call_instruct(receiver_val, :const_set, const_name_val, rhs_val, value: false, raise: false)
            rhs_val
          when :mlhs_paren
            # rhs may or may not be evaluated, and we're okay with that
            multiple_assign_instruct(lhs[1], rhs, opts)
          else
            if Bindings::Base === rhs
              rhs_val = rhs
            elsif rhs.type == :mrhs_new_from_args || rhs.type == :args_add_star ||
                  rhs.type == :mrhs_add_star
              fixed, varying = compute_fixed_and_varying_rhs(rhs)
              rhs_val = combine_fixed_and_varying(fixed, varying)
            else
              rhs_val = walk_node rhs, value: true
            end
            
            var_name = lhs.expanded_identifier
            if lhs.type == :@ident || lhs[1].type == :@ident
              lhs.binding = current_scope.lookup_or_create_local(var_name)
              copy_instruct lhs.binding, rhs_val
            elsif lhs[1].type == :@const
              call_instruct(current_namespace, :const_set, const_instruct(var_name), rhs_val, value: false, raise: false)
            elsif lhs[1].type == :@ivar
              call_instruct(current_self, :instance_variable_set, const_instruct(var_name),
                  rhs_val, value: true, ignore_privacy: true)
            elsif lhs[1].type == :@gvar
              call_instruct(ClassRegistry['Laser#Magic'].binding, :set_global,
                  const_instruct(var_name), rhs_val, raise: false, value: true)
            end
            rhs_val
          end
        end

        def wasted_val(val)
          val.add_error(DiscardedRHSError.new("RHS value being discarded", val))
        end

        def wasted_var(var)
          if var.type == :field || var.type == :aref_field || var.type == :mlhs_paren
            var.add_error(UnassignedLHSError.new("LHS never assigned - defaults to nil", var))
          else
            var.add_error(UnassignedLHSError.new("LHS (#{var.expanded_identifier}) never assigned - defaults to nil", var))
          end
        end

        def wasted_lhs_splat(var, attachment_node)
          if var.nil?
            attachment_node.add_error(UnassignedLHSError.new("Unnamed LHS splat is always empty ([]) - not useful", attachment_node))
          elsif var.type == :field || var.type == :aref_field || var.type == :mlhs_paren
            var.add_error(UnassignedLHSError.new("LHS splat is always empty ([]) - not useful", var))
          else
            var.add_error(UnassignedLHSError.new("LHS splat (#{var.expanded_identifier}) is always empty ([]) - not useful", var))
          end
        end

        def wasted_rhs_splat(val)
          val.add_error(DiscardedRHSError.new("RHS splat expanded and then discarded", val))
        end

        def issue_wasted_val_warnings(list)
          list.each { |val| wasted_val(val) }
        end

        def issue_wasted_var_warnings(list)
          list.each { |val| wasted_var(val) }
        end

        # Expands a multiple-assignment as optimally as possible. Without any
        # splats, will expand to sequential assignments.
        def multiple_assign_instruct(lhs, rhs, opts={})
          rhs_has_star = rhs.find_type(:mrhs_add_star) || rhs.find_type(:args_add_star)
          # a, b = c, d, e
          if lhs.type != :mlhs_add_star && !rhs_has_star
            # a, b = c, d, e
            # tries to generate maximally efficient code: computes
            # precise assignments to improve analysis.
            if Sexp === lhs[0] && rhs.type == :mrhs_new_from_args
              rhs = rhs[1] + [rhs[2]]  # i assume some parser silliness does this
              # issue warnings
              if lhs.size < rhs.size
                issue_wasted_val_warnings(rhs[lhs.size..-1])
              elsif lhs.size > rhs.size
                issue_wasted_var_warnings(lhs[rhs.size..-1])
              end
              # pair them up. Enumerable#zip in 1.9.2 doesn't support unmatched lengths
              
              pairs = (0...[lhs.size, rhs.size].max).map do |idx|
                need_temp = opts[:value] || (lhs[idx] && rhs[idx])
                { lhs: lhs[idx], rhs: rhs[idx], need_temp: need_temp }
              end
              # compute the rhs node
              pairs_with_vals = pairs.map do |hash|
                # only walk rhs if it exists
                result = hash[:rhs] && walk_node(hash[:rhs], value: hash[:need_temp])
                hash.merge(value: result)
              end
              # perform necessary assignments
              pairs_with_vals.each do |hash|
                if hash[:lhs]
                  hash[:value] ||= const_instruct(nil)
                  new_value = hash[:value]
                  single_assign_instruct(hash[:lhs], new_value, value: false)
                end
              end
              # if we need the value, we need to return all the RHS in an array.
              if opts[:value]
                result_temps = pairs_with_vals.map { |hash| hash[:value] }
                call_instruct(ClassRegistry['Array'].binding, :[], *result_temps,
                    value: true, raise: false)
              end
            # a, b, c = foo
            # no star on RHS means implicit conversion: to_ary.
            elsif Sexp === lhs[0] && rhs.type != :mrhs_new_from_args
              rhs_val = walk_node(rhs, value: true)
              rhs_array = rb_ary_to_ary(rhs_val)
              declare_instruct(:expect_tuple_size, :==, lhs.size, rhs_array)
              lhs.each_with_index do |node, idx|
                assigned_val = call_instruct(rhs_array, :[], const_instruct(idx),
                    value: true, raise: false)
                single_assign_instruct(node, assigned_val)
              end
              rhs_array
            else
              raise ArgumentError.new("Unexpected non-starred massign node:\n" +
                                      "  lhs = #{lhs.inspect}\n  rhs = #{rhs.inspect}")
            end
          # a, *b, c = [1, 2, 3]
          # implicit #to_ary
          elsif lhs.type == :mlhs_add_star && !rhs_has_star && rhs.type != :mrhs_new_from_args
            # calculate RHS: array of unknown length
            rhs_val = walk_node(rhs, value: true)
            rhs_array = rb_ary_to_ary(rhs_val)
            assign_splat_mlhs_to_varying(lhs[1], lhs[2], lhs[3] || [], rhs_array)
          # a, *b, c = 1, 2, 3, 4, 5
          # also easy/precise
          elsif lhs.type == :mlhs_add_star && !rhs_has_star
            # RHS = :mrhs_new_from_args
            # single_val not handled yet.
            rhs_arr = rhs[1] + [rhs[2]]
            
            # Calculate pre-star, star, and post-star bindings and boundaries
            pre_star  = lhs[1]  # [], if empty
            star_node = lhs[2]  # could be nil
            post_star = lhs[3] || []
            
            star_start = pre_star.size
            star_end   = [star_start, rhs_arr.size - post_star.size].max
            star_range = star_start...star_end

            if star_range.entries.empty?
              wasted_lhs_splat(star_node, lhs)
            end

            # all RHS are ALWAYS consumed. But if the star is unnamed, star values can be
            # discarded.
            rhs_vals = rhs_arr.map.with_index do |node, idx|
              if !opts[:value] && star_node.nil? && star_range.include?(idx)
                walk_node(node, value: false)
                nil
              else
                walk_node(node, value: true)
              end
            end

            # do pre-star nodes
            pre_star.each_with_index do |lhs_node, idx|
              single_assign_instruct(lhs_node, rhs_vals[idx] || const_instruct(nil))
            end
            # do star assignment if star_node != nil
            if star_node
              star_parts = rhs_vals[star_range]
              star_arr = call_instruct(ClassRegistry['Array'].binding, :[], *star_parts,
                  value: true, raise: false)
              single_assign_instruct star_node, star_arr
            end
            # do post-star nodes
            post_star.each_with_index do |lhs_node, idx|
              single_assign_instruct(lhs_node, rhs_vals[star_end + idx] || const_instruct(nil))
            end
            if opts[:value]
              call_instruct(ClassRegistry['Array'].binding, :[], *rhs_vals,
                  value: true, raise: false)
            end
          # a, b, c = 1, *foo
          elsif lhs.type != :mlhs_add_star && rhs_has_star
            # for building the final array
            lhs_size = lhs.size
            fixed, varying = compute_fixed_and_varying_rhs(rhs)
            fixed_size = fixed.size
            if fixed_size >= lhs_size
              wasted_rhs_splat(rhs)
            else
              declare_instruct(:expect_tuple_size, :==, lhs_size - fixed_size, varying)
            end
            fixed[0...lhs_size].each_with_index do |val, idx|
              single_assign_instruct(lhs[idx], val)
            end
            fixed_size.upto(lhs_size - 1) do |idx|
              looked_up = call_instruct(varying, :[], const_instruct(idx - fixed_size), value: true, raise: false)
              single_assign_instruct(lhs[idx], looked_up)
            end
            if fixed.empty?
              result = varying
            else
              fixed_as_arr = call_instruct(ClassRegistry['Array'].binding, :[], *fixed, value: true, raise: false)
              result = call_instruct(fixed_as_arr, :+, varying, value: true, raise: false)
            end
            result
          # a, *b, c = d, *e
          elsif lhs.type == :mlhs_add_star && rhs_has_star
            # Calculate pre-star, star, and post-star bindings and boundaries
            fixed, varying = compute_fixed_and_varying_rhs(rhs)
            # inefficient: ignore fixed stuff
            # TODO(adgar): optimize this
            rhs_array = combine_fixed_and_varying(fixed, varying)
            assign_splat_mlhs_to_varying(lhs[1], lhs[2], lhs[3] || [], rhs_array)
          else
            raise ArgumentError.new("Unexpected :massign node:\n  " +
                                    "lhs = #{lhs.inspect}\n  rhs = #{rhs.inspect}")
          end
        end
        
        def assign_splat_mlhs_to_varying(pre_star, star_node, post_star, rhs_array)
          # pre-star is easy: how they are extracted is deterministic
          pre_star.each_with_index do |lhs_node, idx|
            assigned_val = call_instruct(rhs_array, :[], const_instruct(idx),
                value: true, raise: false)
            single_assign_instruct(lhs_node, assigned_val)
          end
          
          # next, extract star_node. run-time version of below
          star_start = const_instruct(pre_star.size)
          fixed_size = const_instruct(pre_star.size + post_star.size)
          declare_instruct(:expect_tuple_size, :>, pre_star.size + post_star.size, rhs_array)
          # calculate star_end at runtime without loops
          rhs_arr_size = call_instruct(rhs_array, :size,
              value: true, raise: false)
          star_size = call_instruct(rhs_arr_size, :-, fixed_size,
              value: true, raise: false)
          
          after = create_block

          if_nonempty = build_block_with_jump(after) do
            if star_node
              star_subarray = call_instruct(rhs_array, :[], star_start, star_size,
                  value: true, raise: false)
              single_assign_instruct(star_node, star_subarray)
            end
            if post_star.any?
              post_star_start = call_instruct(star_start, :+, star_size,
                  value: true, raise: false)
              post_star_array = call_instruct(rhs_array, :[], post_star_start,
                  const_instruct(post_star.size), value: true, raise: false)
              post_star.each_with_index do |lhs_node, idx|
                assigned_val = call_instruct(post_star_array, :[], const_instruct(idx),
                    value: true, raise: false)
                single_assign_instruct(lhs_node, assigned_val)
              end
            end
          end
          
          if_empty = build_block_with_jump(after) do
            single_assign_instruct(star_node, const_instruct([])) if star_node
            post_star.each_with_index do |lhs_node, idx|
              assigned_val = call_instruct(rhs_array, :[], const_instruct(pre_star.size + idx),
                  value: true, raise: false)
              single_assign_instruct(lhs_node, assigned_val)
            end
          end
          
          cond_value = call_instruct(star_size, :>, const_instruct(0),
              value: true, raise: false)
          cond_instruct(cond_value, if_nonempty, if_empty)

          start_block after
          rhs_array
        end
        
        # Computes the fixed portion of the RHS, and the varying portion of the
        # RHS. The fixed portion will be an array of temporaries, the varying
        # portion will be an array temporary.
        def compute_fixed_and_varying_rhs(node)
          case node[0]
          when :mrhs_add_star, :args_add_star
            pre_star, star = node[1], node[2]
            post_star = node[3..-1]
            # pre_star could have more stars!
            fixed, varying = compute_fixed_and_varying_rhs(pre_star)
            # varying had better be []
            star_pre_conv = walk_node(star, value: true)
            star_vals = rb_check_convert_type(star_pre_conv, ClassRegistry['Array'].binding, :to_a)
            # if we had varying parts, then we append the star, otherwise, the star IS
            # the varying part
            if varying
              varying = call_instruct(varying, :+, star_vals, value: true, raise: false)
            else
              varying = star_vals
            end
            # if we have a post-star section, append to varying
            if post_star && !post_star.empty?
              post_star_vals = build_array_instruct(post_star)
              varying = call_instruct(varying, :+, post_star_vals, value: true, raise: false)
            end
          when :mrhs_new_from_args
            # random spare node when mrhs is just used for fixed rhs
            fixed, varying = compute_fixed_and_varying_rhs(node[1])
            if node[2]
              if varying.nil?
              then fixed << walk_node(node[2], value: true)
              else varying = call_instruct(varying, :+, build_array_instruct([node[2]]), value: true, raise: false)
              end
            end
          when Sexp, NilClass
            fixed = node.map { |val| walk_node(val, value: true) }
            varying = nil
          end
          [fixed, varying]
        end

        # Combines an array of fixed temporaries and an array temporary that contains
        # an unknown number of temporaries.
        def combine_fixed_and_varying(fixed, varying)
          if fixed.empty?
            varying || const_instruct([])
          else
            fixed_ary = call_instruct(ClassRegistry['Array'].binding, :[], *fixed, value: true, raise: false)
            if varying
              call_instruct(fixed_ary, :+, varying, value: true, raise: false)
            else
              fixed_ary
            end
          end
        end

        def foreach_on_rhs(node, &blk)
          case node[0]
          when :mrhs_add_star, :args_add_star
            foreach_on_rhs(node[1], &blk)
            array_to_iterate = walk_node node[2], value: true
            counter = lookup_or_create_temporary(:rescue_iterator)
            copy_instruct(counter, 0)
            max = call_instruct(array_to_iterate, :size, value: true, raise: false)
            
            loop_start_block, after = create_blocks 2
            
            uncond_instruct loop_start_block
            cond_result = call_instruct(counter, :<, max, value: true, raise: false)
            
            check_block = build_block_with_jump(loop_start_block) do
              current_val = call_instruct(array_to_iterate, :[], counter, value: true, raise: false)
              yield current_val
              next_counter = call_instruct(counter, :+, 1, value: true, raise: false)
              copy_instruct(counter, next_counter)
            end
            
            cond_instruct(cond_result, check_block, after)
            start_block after
          when :mrhs_new_from_args
            foreach_on_rhs(node[1], &blk)
            yield walk_node(node[2], value: true) if node[2]
          when Sexp
            node.each { |val_node| yield walk_node(val_node, value: true) }
          end
        end

        # Implicit conversion protocol to an array.
        def rb_ary_to_ary(value)
          result = lookup_or_create_temporary(:ary_to_ary, value)
          try_conv = rb_check_convert_type(value, ClassRegistry['Array'].binding, :to_ary)
          
          after = create_block
          if_conv_succ = build_block_with_jump(after) do
            copy_instruct(result, try_conv)
          end
          if_conv_fail = build_block_with_jump(after) do
            new_result = call_instruct(ClassRegistry['Array'].binding, :[], value,
                value: true, raise: false)
            copy_instruct(result, new_result)
          end
          
          cond_instruct(try_conv, if_conv_succ, if_conv_fail)
          
          start_block after
          result
        end

        #TODO(adgar): RAISES HERE!
        def rb_check_convert_type(value, klass, method)
          result = lookup_or_create_temporary(:convert, value, klass, method)
          after = create_block
          
          comparison_result = call_instruct(klass, :===, value, value: true)
          
          if_not_klass_block = build_block_with_jump do
            # TODO(adgar): if method does not exist, return nil.
            has_method = call_instruct(ClassRegistry['Laser#Magic'].binding, :responds?,
                value, const_instruct(method), value: true, raise: false)

            if_has_method_block = build_block_with_jump(after) do
              conversion_result = call_instruct(value, method, value: true)
              copy_instruct result, conversion_result
            end
            if_no_method_block = build_block_with_jump(after) do
              copy_instruct result, const_instruct(nil)
              declare_instruct(:alias, result, value)
            end
            cond_instruct(has_method, if_has_method_block, if_no_method_block)
          end
          if_klass_block = build_block_with_jump(after) do
            copy_instruct(result, value)
          end
          
          cond_instruct(comparison_result, if_klass_block, if_not_klass_block)
          
          start_block after
          result
        end
        
        def explicit_block_arg(method_call)
          if (to_proc = method_call.arguments.block_arg)
            to_proc_val = walk_node(to_proc, value: true)
            rb_check_convert_type(to_proc_val, ClassRegistry['Proc'].binding, :to_proc)
          end
        end
        
        def issue_call(node, opts={})
          opts = {value: true}.merge(opts)
          method_call = node.method_call
          opts = opts.merge(ignore_privacy: true) if method_call.implicit_receiver?
          receiver = receiver_instruct node
          block = explicit_block_arg(method_call)
          generic_call_instruct(receiver, method_call.method_name,
              method_call.arg_node, block, opts)
        end
        
        def issue_super_call(node, opts={})
          method_call = node.method_call
          opts = opts.merge(ignore_privacy: true)
          block = explicit_block_arg(method_call)
          generic_super_instruct(method_call.arg_node, block, opts)
        end
        
        def receiver_instruct(node)
          method_call = node.method_call
          if method_call.receiver_node
          then walk_node method_call.receiver_node, value: true
          else self_instruct
          end
        end
        
        # Given a receiver, a method, a method_add_arg node, and a block value,
        # issue a call instruction. This will involve computing the arguments,
        # potentially issuing a vararg call (if splats are used). The return
        # value is captured and returned to the caller of this method.
        def generic_call_instruct(receiver, method, args, block, opts={})
          opts = {value: true}.merge(opts)
          args = [] if args.nil?
          args = args[1] if args[0] == :args_add_block
          if args[0] == :args_add_star
            arg_array = compute_varargs(args)
            call_vararg_instruct(receiver, method, arg_array, {block: block}.merge(opts))
          else
            arg_temps = args.map { |arg| walk_node(arg, value: true) }
            call_instruct(receiver, method, *arg_temps, {block: block}.merge(opts))
          end
        end

        # Given a receiver, a method, a method_add_arg node, and a block value,
        # issue a super instruction. This will involve computing the arguments,
        # potentially issuing a vararg super (if splats are used). The return
        # value is captured and returned to the superer of this method.
        def generic_super_instruct(args, block, opts={})
          opts = {value: true, raise: true}.merge(opts)
          args = args[1] if args[0] == :args_add_block
          if args[0] == :args_add_star
            arg_array = compute_varargs(args)
            super_vararg_instruct(arg_array, {block: block}.merge(opts))
          else
            arg_temps = args.map { |arg| walk_node(arg, value: true) }
            super_instruct(*arg_temps, {block: block}.merge(opts))
          end
        end

        # Given a receiver, a method, a method_add_arg node, and a block value,
        # issue a call instruction. This will involve computing the arguments,
        # potentially issuing a vararg call (if splats are used). The return
        # value is captured and returned to the caller of this method.
        def generic_aref_instruct(receiver, args, val, opts={})
          opts = {value: true, raise: true}.merge(opts)
          args = [] if args.nil?
          args = args[1] if args[0] == :args_add_block
          if args[0] == :args_add_star
            arg_array = compute_varargs(args)
            call_instruct(arg_array, :<<, walk_node(val, value: true), value: false)
            call_vararg_instruct(receiver, :[]=, arg_array, false, opts)
          else
            arg_temps = (args + [val]).map { |arg| evaluate_if_needed(arg, value: true) }
            call_instruct(receiver, :[]=, *arg_temps, {block: false}.merge(opts))
          end
        end

        # Computes the arguments to a zsuper call at the given node. Also returns
        # whether the resulting argument expansion is of variable arity.
        # This is different from normal splatting because we are computing based
        # upon the argument list of the method, not a normal arg_ node.
        #
        # returns: (Bindings::Base | [Bindings::Base], Boolean)
        def compute_zsuper_arguments
          args_to_walk = @formals
          is_vararg = args_to_walk.any? { |arg| arg.kind == :rest }
          if is_vararg
            index_of_star = args_to_walk.index { |arg| arg.kind == :rest }
            # re-splatting vararg super call. assholes
            
            pre_star = args_to_walk[0...index_of_star]
            result = call_instruct(ClassRegistry['Array'].binding, :[], *pre_star,
                                   value: true, raise: false)
            result = call_instruct(result, :+, args_to_walk[index_of_star],
                                   value: true, raise: false)
            
            post_star = args_to_walk[index_of_star+1 .. -1]
            post_star_temp = call_instruct(ClassRegistry['Array'].binding, :[], *post_star,
                                           value: true, raise: false)
            result = call_instruct(result, :+, post_star_temp, value: true, raise: false)
            [result, is_vararg]
          else
            [args_to_walk, is_vararg]
          end
        end

        # Computes a splatting node (:args_add_star)
        def compute_varargs(args)
          result = call_instruct(ClassRegistry['Array'].binding, :new, value: true, raise: false)
          if args[1][0] == :args_add_star || args[1].children.any?
            prefix = if args[1][0] == :args_add_star
                     then compute_varargs(args[1])
                     else prefix = build_array_instruct(args[1].children)
                     end
            result = call_instruct(result, :+, prefix, value: true, raise: false)
          end
          starred = walk_node args[2], value: true
          starred_converted = rb_check_convert_type(starred, ClassRegistry['Array'].binding, :to_a)
          result = call_instruct(result, :+, starred_converted, value: true, raise: false)
          if args[3..-1].any?
            suffix = build_array_instruct(args[3..-1])
            result = call_instruct(result, :+, suffix, value: true, raise: false)
          end
          result
        end

        # Adds a generic method call instruction.
        def call_instruct(receiver, method, *args)
          opts = {raise: true}
          opts.merge!(args.last) if Hash === args.last
          result = create_result_if_needed opts
          call_opts = { ignore_privacy: opts[:ignore_privacy] }
          add_instruction_with_opts(:call, result, receiver, method.to_sym, *args, call_opts)
          add_potential_raise_edge if opts[:raise]
          result
        end
        
        # Adds a generic method call instruction.
        def call_vararg_instruct(receiver, method, args, opts={})
          opts = {raise: true, value: true}.merge(opts)
          result = create_result_if_needed opts
          call_opts = { ignore_privacy: opts[:ignore_privacy] }
          add_instruction_with_opts(:call_vararg, result, receiver, method.to_sym, args, opts, call_opts)
          add_potential_raise_edge if opts[:raise]
          result
        end
        
        # Adds a generic method super instruction.
        def super_instruct(*args)
          opts = (Hash === args.last) ? args.last : {}
          result = create_result_if_needed opts

          add_instruction(:super, result, *args)
          add_potential_raise_edge
          result
        end
        
        # Adds a generic method super instruction.
        def super_vararg_instruct(args, block, opts={})
          opts = {raise: true, value: true}.merge(opts)
          result = create_result_if_needed opts
          add_instruction(:super_vararg, result, args, block)
          add_potential_raise_edge if opts[:raise]
          result
        end

        # Adds an edge from the current block to the current rescue target,
        # while creating a new block for the "natural" exit.
        def add_potential_raise_edge(add_success_branch = true)
          fail_block = create_block
          @graph.add_edge(@current_block, fail_block, RGL::ControlFlowGraph::EDGE_ABNORMAL)
          with_current_basic_block(fail_block) do
            observe_just_raised_exception
            uncond_instruct current_rescue, flags: RGL::ControlFlowGraph::EDGE_ABNORMAL
          end
          uncond_instruct create_block, jump_instruct: false if add_success_branch
        end

        # Looks up the value of a variable and assigns it to a new temporary
        def variable_instruct(var_ref)
          return self_register if var_ref.expanded_identifier == 'self'
          var_named_instruct var_ref.expanded_identifier
        end
        
        def var_named_instruct(var_name)
          binding = current_scope.lookup_or_create_local(var_name)
          result = lookup_or_create_temporary(:var, binding)
          copy_instruct result, binding
          result
        end
        
        # Performs constant lookup.
        # TODO(adgar): FULL CONSTANT LOOKUP w/ SUPERCLASS CHECKING ETC
        def const_lookup(const_name)
          ident = const_instruct(const_name)
          call_instruct(current_namespace,
              :const_get, ident, value: true, ignore_privacy: true)
        end

        # Performs constant definition checking.
        # TODO(adgar): FULL CONSTANT LOOKUP w/ SUPERCLASS CHECKING ETC
        def const_defined?(const_name)
          ident = const_instruct(const_name)
          call_instruct(current_namespace,
              :const_defined?, ident, value: true, ignore_privacy: true)
        end
        
        def binary_instruct(lhs, op, rhs, opts={})
          opts = {value: true}.merge(opts)
          if op == :or || op == :"||"
            return or_instruct(lhs, rhs, opts)
          elsif op == :and || op == :"&&"
            return and_instruct(lhs, rhs, opts)
          end

          lhs_result = walk_node lhs, value: true
          rhs_result = walk_node rhs, value: true
          call_instruct(lhs_result, op, rhs_result, opts)
        end
        
        def ternary_instruct(cond, if_true, if_false, opts={})
          opts = {value: true}.merge(opts)
          if_true_block, if_false_block, after = create_blocks 3
          cond_result = walk_node cond, value: true
          cond_instruct(cond_result, if_true_block, if_false_block)
          
          start_block if_true_block
          if_true_result = walk_node if_true, opts
          if_true_block = @current_block
          
          start_block if_false_block
          if_false_result = walk_node if_false, opts
          if_false_block = @current_block
          
          # generate temporary if necessary
          result = opts[:value] ? 
                   lookup_or_create_temporary(:ternary, cond_result, if_true_result, if_false_result) :
                   nil
          
          start_block if_true_block
          copy_instruct(result, if_true_result) if opts[:value]
          uncond_instruct(after)
          
          start_block if_false_block
          copy_instruct(result, if_false_result) if opts[:value]
          uncond_instruct(after)
          
          start_block after
          result
        end
        
        # Runs the list of operations in body while the condition is true.
        # Then returns nil.
        def while_instruct(condition, body, opts={})
          opts = {value: true}.merge(opts)
          body_block, after_block, precond_block = create_blocks 3

          with_jump_targets(break: after_block, redo: body_block, next: precond_block) do
            uncond_instruct precond_block
            start_block precond_block
            
            cond_result = walk_node condition, value: true
            cond_instruct(cond_result, body_block, after_block)

            start_block body_block
            walk_body body, value: false
            cond_result = walk_node condition, value: true
            cond_instruct(cond_result, body_block, after_block)
          end
          
          start_block after_block
          const_instruct(nil) if opts[:value]
        end
        
        # Runs the list of operations in body until the condition is true.
        # Then returns nil.
        def until_instruct(condition, body, opts={})
          opts = {value: true}.merge(opts)
          body_block, after_block, precond_block = create_blocks 3

          with_jump_targets(break: after_block, redo: body_block, next: precond_block) do
            uncond_instruct precond_block
            start_block precond_block
            
            cond_result = walk_node condition, value: true
            cond_instruct(cond_result, after_block, body_block)

            start_block body_block
          
            walk_body body, value: false
            cond_result = walk_node condition, value: true
            cond_instruct(cond_result, after_block, body_block)
          end
          
          start_block after_block
          const_instruct(nil) if opts[:value]
        end
        
        # Performs an OR operation, with short circuiting that must save
        # the result of the operation.
        def or_instruct(lhs, rhs, opts={})
          opts = {value: true}.merge(opts)
          if opts[:value]
          then or_instruct_value(lhs, rhs)
          else or_instruct_novalue(lhs, rhs)
          end
        end

        # Performs a short-circuit OR operation while retaining the resulting value.
        def or_instruct_value(lhs, rhs)
          after = create_block

          lhs_result = walk_node lhs, value: true
          
          result = nil
          false_block = build_block_with_jump(after) do
            rhs_result = walk_node rhs, value: true
            result = lookup_or_create_temporary(:or_short_circuit, lhs_result, rhs_result)
            copy_instruct(result, rhs_result)
          end
          true_block = build_block_with_jump(after) do
            copy_instruct(result, lhs_result)
          end
          
          cond_instruct(lhs_result, true_block, false_block)
        
          start_block(after)
          result
        end

        # Performs a short-circuit OR operation while discarding the resulting value.
        def or_instruct_novalue(lhs, rhs)
          after = create_block

          lhs_result = walk_node lhs, value: true

          false_block = build_block_with_jump(after) do
            walk_node rhs, value: false
          end
          cond_instruct(lhs_result, after, false_block)

          start_block(after)
        end

        # Performs an AND operation, with short circuiting, that must save
        # the result of the operation.
        def and_instruct(lhs, rhs, opts={})
          opts = {value: true}.merge(opts)
          if opts[:value]
          then and_instruct_value(lhs, rhs)
          else and_instruct_novalue(lhs, rhs)
          end
        end
        
        # Performs a short-circuit AND operation while retaining the resulting value.
        def and_instruct_value(lhs, rhs)
          after = create_block

          lhs_result = walk_node lhs, value: true
          
          result = nil
          true_block = build_block_with_jump(after) do
            rhs_result = walk_node rhs, value: true
            result = lookup_or_create_temporary(:and_short_circuit, lhs_result, rhs_result)
            copy_instruct(result, rhs_result)
          end
          false_block = build_block_with_jump(after) do
            copy_instruct(result, lhs_result)
          end
          cond_instruct(lhs_result, true_block, false_block)

          start_block(after)
          result
        end
        
        # Performs a short-circuit AND operation while discarding the resulting value.
        def and_instruct_novalue(lhs, rhs)
          after = create_block

          lhs_result = walk_node lhs, value: true

          true_block = build_block_with_jump(after) do
            walk_node rhs, value: false
          end
          cond_instruct(lhs_result, true_block, after)
          start_block(after)
        end

        # Performs a value-capturing if instruction, with unlimited else-ifs
        # and a potential else block.
        #
        # condition: Sexp
        # body: [Sexp]
        # else_block: Sexp | NilClass
        def if_instruct(node, is_mod=false, opts={})
          opts = {value: true}.merge(opts)
          if opts[:value]
          then if_instruct_value(node, is_mod)
          else if_instruct_novalue(node, is_mod)
          end
        end

        def if_instruct_value(node, is_mod=false)
          result = create_temporary
          after = create_block
          current = node
          next_block = nil
          
          while current
            if current.type == :else
              true_block = next_block
              body, next_block, else_block = current[1], after, nil
            else
              true_block = create_block
              condition, body, else_block = current.children
              next_block = create_block
              
              cond_result = walk_node condition, value: true
              cond_instruct(cond_result, true_block, next_block)
            end
            
            start_block true_block
            body = [body] if is_mod
            body_result = walk_body body, value: true
            copy_instruct(result, body_result)
            uncond_instruct(after)
            
            start_block next_block
            # check: is there no else at all, and we're about to break out of the loop?
            if current.type != :else && else_block.nil?
              copy_instruct(result, nil)
              uncond_instruct(after)
              start_block after
            end
            current = else_block
          end
          result
        end
        
        # Performs an if instruction that ignores result values, with unlimited else-ifs
        # and a potential else block.
        #
        # condition: Sexp
        # body: [Sexp]
        # else_block: Sexp | NilClass
        def if_instruct_novalue(node, is_mod=false)
          current = node
          after = create_block
          next_block = nil
          
          while current
            if current.type == :else
              true_block = next_block
              body, next_block, else_block = current[1], after, nil
            else
              true_block = create_block
              condition, body, else_block = current.children
              next_block = else_block ? create_block : after
              
              cond_result = walk_node condition, value: true
              cond_instruct(cond_result, true_block, next_block)
            end
            
            start_block true_block
            body = [body] if is_mod
            walk_body body, value: false
            uncond_instruct(after)
            
            start_block next_block
            current = else_block
          end
        end
        
        def unless_instruct(condition, body, else_block, opts={})
          opts = {value: true}.merge(opts)
          if opts[:value]
          then unless_instruct_value(condition, body, else_block)
          else unless_instruct_novalue(condition, body, else_block)
          end
        end
        
        # Performs a value-capturing unless instruction.
        #
        # condition: Sexp
        # body: [Sexp]
        # else_block: Sexp | NilClass
        def unless_instruct_value(condition, body, else_block)
          result = create_temporary
          after = create_block

          cond_result = walk_node condition, value: true

          true_block = build_block_with_jump(after) do
            body_result = walk_body body, value: true
            copy_instruct(result, body_result)
          end

          next_block = build_block_with_jump(after) do
            body_result = if else_block
                          then walk_body else_block[1], value: true
                          else const_instruct nil
                          end
            copy_instruct result, body_result
          end

          cond_instruct(cond_result, next_block, true_block)

          start_block after
          result
        end
        
        # Performs an unless instruction, ignoring the potential that its value
        # is saved.
        #
        # condition: Sexp
        # body: [Sexp]
        # else_block: Sexp | NilClass
        def unless_instruct_novalue(condition, body, else_block)
          after, true_block = create_blocks 2
          next_block = else_block ? create_block : after
          
          cond_result = walk_node condition, value: true
          cond_instruct(cond_result, next_block, true_block)
          
          start_block true_block
          walk_body body, value: false
          uncond_instruct(after)
          
          if else_block
            start_block next_block
            else_block[1].each { |elt| walk_node(elt, value: false) }
            uncond_instruct(after)
          end
          
          start_block after
        end
        
        def defined_op_instruct(expression)
          case expression.type
          when :yield0, :yield
            # give 'yield' if there is a block, otherwise nil
            result = lookup_or_create_temporary(:defined, :yield)
            after = create_block
            with_block_block = build_block_with_jump(after) do
              copy_instruct(result, const_instruct('yield'))
            end
            without_block_block = build_block_with_jump(after) do
              copy_instruct(result, const_instruct(nil))
            end
            cond_instruct(@block_arg, with_block_block, without_block_block)
            start_block after
            result
          when :assign, :massign
            const_instruct('assignment')
          when :var_ref
            case expression[1].type
            when :@ident
              const_instruct('local-variable')
            when :@kw
              case expression[1][1]
              when 'nil' then const_instruct('nil')
              when 'self' then const_instruct('self')
              when 'true' then const_instruct('true')
              when 'false' then const_instruct('false')
              when '__FILE__', '__LINE__', '__ENCODING__' then const_instruct('expression')
              else
                raise NotImplementedError.new("defined? on keyword #{expression[1][1]}")
              end
            when :@const
              const_defined?(expression.expanded_identifier)
            when :@ivar
              
            when :@cvar
              
            when :@gvar
            end
          when :string_literal, :and, :or, :@int, :@float, :symbol_literal
            const_instruct('expression')
          else
            raise NotImplementedError.new("Unimplemented defined? case: #{expression.type}")
          end
        end
        
        # Takes a set of either :@tstring_content or :string_embexpr nodes
        # and constructs a string out of them. (In other words, this computes
        # the contents of possibly-interpolated strings).
        def build_string_instruct(components)
          temp = const_instruct('')
          components.each do |node|
            as_string = walk_node node, value: true
            temp = call_instruct(temp, :+, as_string, value: true, raise: false)
          end
          temp
        end
        
        # Takes a set of nodes, finds their values, and builds a temporary holding
        # the array containing them.
        def build_array_instruct(components)
          args = components.map { |arg| walk_node(arg, value: true) }
          call_instruct(ClassRegistry['Array'].binding, :[], *args, value: true, raise: false)
        end
        
        # CL-style compiler hint generation.
        def declare_instruct(kind, *args)
          verify_declare_instruction(kind, args)
          add_instruction(:declare, kind, *args)
        end
        
        def verify_declare_instruction(kind, args)
          case kind
          when :alias
            if args.size != 2
              raise ArgumentError.new("declare :alias requires 2 args")
            end
          when :expect_tuple_size
            if args.size != 3
              raise ArgumentError.new('declare :expect_tuple_size requires 3 args')
            end
          end
        end
        
        def create_result_if_needed(opts)
          value = opts.delete(:value)
          value ? create_temporary : nil
        end
        
        def add_fake_edge(from, to)
          @graph.add_edge(from, to, RGL::ControlFlowGraph::EDGE_FAKE)
        end
        
        # Returns the name of the current temporary.
        def current_temporary(prefix='t')
          "%#{prefix}#{@temporary_counter}"
        end

        # Creates a temporary variable with an unused name.
        def create_temporary(name = nil)
          unless name
            @temporary_counter += 1
            name = current_temporary
          end
          Bindings::TemporaryBinding.new(name, nil)
        end
        
        # Creates a block temporary variable with an unused name.
        def create_block_temporary(args, body, callsite_block=nil)
          @temporary_counter += 1
          name = current_temporary('B-')
          if callsite_block
            new_proc = LaserProc.new(args, body, @graph, callsite_block)
          else
            new_proc = LaserProc.new(args, body)
          end
          binding = Bindings::BlockBinding.new(name, nil)
          add_instruction(:assign, binding, new_proc)
          [binding, new_proc]
        end
        
        def lookup_or_create_temporary(*keys)
          @temporary_table[keys]
        end
        
        # Adds a simple instruction to the current basic block.
        def add_instruction(*args)
          @current_block.instructions << Instruction.new(args, node: @current_node,
                                                               block: @current_block)
        end

        # Adds a simple instruction to the current basic block.
        def add_instruction_with_opts(*args, opts)
          opts = {node: @current_node, block: @current_block}.merge(opts)
          i = Instruction.new(args, opts)
          @current_block.instructions << Instruction.new(args, opts)
        end
        
        # Creates the given number of blocks.
        def create_blocks(count)
          (0...count).to_a.map { create_block }
        end

        # Creates a new basic block for flow analysis.
        def create_block(name = 'B' + (@block_counter += 1).to_s)
          result = BasicBlock.new(name)
          @graph.add_vertex result
          result
        end
        
        # Sets the current block to be the given block.
        def start_block(block)
          @current_block = block
        end
      end
    end
  end
end
