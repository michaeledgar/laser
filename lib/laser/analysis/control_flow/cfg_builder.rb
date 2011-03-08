module Laser
  module SexpAnalysis
    module ControlFlow
      # This class builds a control flow graph. The algorithm used is
      # derived from Robert Morgan's "Building an Optimizing Compiler".
      class GraphBuilder
        attr_reader :graph, :enter, :exit, :temporary_counter, :current_block, :sexp
        
        def initialize(sexp)
          @sexp = sexp
          @graph = @enter = @exit = nil
          @temporary_counter = 0
        end
        
        def build
          initialize_graph
          value_walk @sexp
          @graph
        end
        
        # Walks the node expecting that the expression's return value will be discarded.
        # Since everything is an expression in Ruby, knowing when to ignore return
        # values is nice.
        def novalue_walk(node)
          case node.type
          when :void_stmt
            # Do nothing.
          when :assign
            lhs, rhs = node.children
            # TODO(adgar): :field!!!!!!
            assign_instruct(lhs.binding, rhs)
          when :opassign
            lhs, op, rhs = node.children
            op = op.expanded_identifier[0..-2].to_sym
            if lhs.type == :field
              # TODO(adgar): FIELD!!!
            else
              result = create_temporary
              if op == :or || op == :"||"
                result = or_instruct(lhs, rhs)
              elsif op == :and || op == :"&&"
                result = and_instruct(lhs, rhs)
              end
              # all other binary operators
              lhs_result = value_walk lhs
              rhs_result = value_walk rhs
              result = binary_instruct(lhs_result, op, rhs_result)
              copy_instruct(lhs.binding, result)
            end
          when :binary
            # If someone makes an overloaded operator that mutates something....
            # we have to run it (maybe), even if we hate them.
            lhs, op, rhs = node.children
            if op == :or || op == :"||"
              return or_instruct_novalue(lhs, rhs)
            elsif op == :and || opr == :"&&"
              return and_instruct_novalue(lhs, rhs)
            end

            lhs_result = value_walk lhs
            rhs_result = value_walk rhs
            call_instruct_novalue(lhs, op, rhs)
          when :while
            condition, body = node.children
            while_instruct_novalue(condition, body)
          when :while_mod
            condition, body_stmt = node.children
            while_instruct_novalue(condition, [body_stmt])
          when :until
            condition, body = node.children
            until_instruct_novalue(condition, body)
          when :until_mod
            condition, body_stmt = node.children
            until_instruct_novalue(condition, [body_stmt])
          when :if
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
                next_block = else_block ? create_block : after
                
                cond_result = value_walk condition
                cond_instruct(cond_result, true_block, next_block)
              end
              
              start_block true_block
              body.each { |elt| novalue_walk(elt) }
              uncond_instruct(after)
              
              start_block next_block
              current = else_block
            end
          when :unless
            after, true_block = create_blocks 2
            condition, body, else_block = node.children
            next_block = else_block ? create_block : after
            
            cond_result = value_walk condition
            cond_instruct(cond_result, next_block, true_block)
            
            start_block true_block
            body.each { |elt| novalue_walk(elt) }
            uncond_instruct(after)
            
            if else_block
              start_block next_block
              else_block[1].each { |elt| novalue_walk(elt) }
              uncond_instruct(after)
            end
            
            start_block after
          when :return0
            return0_instruct
          when :var_ref
            if node.binding.nil?
              call_instruct_novalue(node.scope.lookup('self'), node.expanded_identifier)
            end
          else
            raise ArgumentError.new("Unknown AST node type #{node.type.inspect}")
          end
        end
        
        # Walks the node with the expectation that the return value will be used.
        def value_walk(node)
          case node.type
          when :bodystmt
            # TODO(adgar): RESCUE, ELSE, ENSURE
            body, rescue_body, else_body, ensure_body = node.children
            body[0..-2].each do |elt|
              novalue_walk(elt)
            end
            return_instruct(body.last)
          when :assign
            lhs, rhs = node.children
            assign_instruct(lhs.binding, rhs)
            # TODO(adgar): :field!!!!!
          when :opassign
            lhs, op, rhs = node.children
            op = op.expanded_identifier[0..-2].to_sym
            if lhs.type == :field
              # TODO(adgar): FIELD!!!
            else
              result = create_temporary
              if op == :or || op == :"||"
                result = or_instruct(lhs, rhs)
              elsif op == :and || op == :"&&"
                result = and_instruct(lhs, rhs)
              end
              # all other binary operators
              lhs_result = value_walk lhs
              rhs_result = value_walk rhs
              result = binary_instruct(lhs_result, op, rhs_result)
              copy_instruct(lhs.binding, result)
              result
            end
          when :binary
            lhs, op, rhs = node.children
            if op == :or || op == :"||"
              return or_instruct(lhs, rhs)
            elsif op == :and || op == :"&&"
              return and_instruct(lhs, rhs)
            end
            # all other binary operators
            lhs_result = value_walk lhs
            rhs_result = value_walk rhs
            binary_instruct(lhs_result, op, rhs_result)
          when :var_field
            variable_instruct(node)
          when :var_ref
            if node.binding
              variable_instruct(node)
            else
              call_instruct(node.scope.lookup('self'), node.expanded_identifier)
            end
          when :while
            condition, body = node.children
            while_instruct(condition, body)
          when :while_mod
            condition, body_stmt = node.children
            while_instruct(condition, [body_stmt])
          when :until
            condition, body = node.children
            until_instruct(condition, body)
          when :until_mod
            condition, body_stmt = node.children
            until_instruct(condition, [body_stmt])
          when :if
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
                
                cond_result = value_walk condition
                cond_instruct(cond_result, true_block, next_block)
              end
              
              start_block true_block
              walk_body_saving_result body, result
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
          when :unless
            result = create_temporary
            after, true_block = create_blocks 2
            condition, body, else_block = node.children
            next_block = else_block ? create_block : after
            
            cond_result = value_walk condition
            cond_instruct(cond_result, next_block, true_block)
            
            start_block true_block
            walk_body_saving_result body, result
            uncond_instruct(after)
            
            if else_block
              start_block next_block
              walk_body_saving_result else_block[1], result
              uncond_instruct(after)
            end
            
            start_block after
            result
          when :return0
            return0_instruct
            const_instruct(nil)
          when :void_stmt
            const_instruct(nil)
          when :@CHAR, :@tstring_content, :@int, :@float, :@regexp_end, :symbol, :@label
            const_instruct(node.constant_value)
          else
            raise ArgumentError.new("Unknown AST node type #{node.type.inspect}")
          end
        end
        
       private
        def initialize_graph
          @graph = ControlFlowGraph.new
          @block_counter = 0
          @enter = create_block('Enter')
          @exit = create_block('Exit')
          @temporary_counter = 0
          
          start_block @enter
        end
        
        def walk_body_saving_result(body, result)
          body[0..-2].each { |elt| novalue_walk(elt) }
          if body.any?
            body_result = value_walk(body.last)
            copy_instruct(result, body_result)
          else
            copy_instruct(result, nil)
          end
        end
        
        # Terminates the current block with a jump to the target block.
        def uncond_instruct(target)
          add_instruction(:jump, target.name)
          @graph.add_edge(@current_block, target)
          start_block target
        end
        
        def cond_instruct(val, true_block, false_block)
          add_instruction(:branch, val, true_block.name, false_block.name)
          @graph.add_edge(@current_block, true_block)
          @graph.add_edge(@current_block, false_block)
        end
        
        def return0_instruct
          add_instruction(:return, nil)
          uncond_instruct @exit
          start_block create_block
        end
        
        def return_instruct(val)
          result = value_walk val
          add_instruction(:return, result)
          uncond_instruct @exit
          start_block create_block
          result
        end

        def const_instruct(val)
          result = create_temporary
          add_instruction(:assign, result, val)
          result
        end
        
        def copy_instruct(lhs, rhs)
          add_instruction(:assign, lhs, rhs)
        end
        
        def assign_instruct(lhs, rhs)
          result = value_walk rhs
          add_instruction(:assign, lhs, result)
          result
        end
        
        def binary_instruct(lhs, op, rhs)
          call_instruct(lhs, op, rhs)
        end

        def call_instruct_novalue(receiver, method, *args)
          add_instruction(:call, nil, receiver, method, *args)
        end
        
        def call_instruct(receiver, method, *args)
          result = create_temporary
          add_instruction(:call, result, receiver, method, *args)
          result
        end
        
        # Looks up the value of a variable and assigns it to a new temporary
        def variable_instruct(var_ref)
          result = create_temporary
          add_instruction(:assign, result, var_ref.binding)
          result
        end
        
        # Runs the list of operations in body while the condition is true.
        def while_instruct_novalue(condition, body)
          body_block, after_block = create_blocks 2

          cond_result = value_walk condition
          cond_instruct(cond_result, body_block, after_block)

          start_block body_block
          body.each { |elt| novalue_walk(elt) }
          cond_result = value_walk condition
          cond_instruct(cond_result, body_block, after_block)
          
          start_block after_block
        end
        
        # Runs the list of operations in body while the condition is true.
        # Then returns nil.
        def while_instruct(condition, body)
          while_instruct_novalue(condition, body)
          const_instruct(nil)
        end
        
        # Runs the list of operations in body until the condition is true.
        def until_instruct_novalue(condition, body)
          body_block, after_block = create_blocks 2

          cond_result = value_walk condition
          cond_instruct(cond_result, after_block, body_block)

          start_block body_block
          body.each { |elt| novalue_walk(elt) }
          cond_result = value_walk condition
          cond_instruct(cond_result, after_block, body_block)
          
          start_block after_block
        end
        
        # Runs the list of operations in body until the condition is true.
        # Then returns nil.
        def until_instruct(condition, body)
          until_instruct_novalue(condition, body)
          const_instruct(nil)
        end
        
        # Performs an OR operation, with short circuiting that must save
        # the result of the operation.
        def or_instruct(lhs, rhs)
          result = create_temporary
          true_block, false_block, after = create_blocks 3

          lhs_result = value_walk lhs
          cond_instruct(lhs_result, true_block, false_block)
          
          start_block(true_block)
          copy_instruct(result, lhs_result)
          uncond_instruct(after)
          
          start_block(false_block)
          rhs_result = value_walk rhs
          copy_instruct(result, rhs_result)
          uncond_instruct(after)
          
          start_block(after)
          result
        end
        
        # Performs an OR operation, with short circuiting, that ignores
        # whatever return value results.
        def or_instruct_novalue(lhs, rhs)
          false_block, after = create_blocks 2

          lhs_result = value_walk lhs
          cond_instruct(lhs_result, after, false_block)
          
          start_block(false_block)
          novalue_walk rhs
          uncond_instruct(after)
          start_block(after)
        end
        
        # Performs an AND operation, with short circuiting, that must save
        # the result of the operation.
        def and_instruct(lhs, rhs)
          result = create_temporary
          true_block, false_block, after = create_blocks 3

          lhs_result = value_walk lhs
          cond_instruct(lhs_result, true_block, false_block)
          
          start_block(true_block)
          rhs_result = value_walk rhs
          copy_instruct(result, rhs_result)
          uncond_instruct(after)
          
          start_block(false_block)
          copy_instruct(result, lhs_result)
          uncond_instruct(after)
          start_block(after)
          
          result
        end
        
        # Performs an AND operation, with short circuiting, that ignores
        # whatever return value results.
        def and_instruct_novalue(lhs, rhs)
          false_block, after = create_blocks 2

          lhs_result = value_walk lhs
          cond_instruct(lhs_result, true_block, after)

          start_block(true_block)
          novalue_walk rhs
          uncond_instruct(after)
          start_block(after)
        end
        
        # Returns the name of the current temporary.
        def current_temporary
          "%t#{@temporary_counter}"
        end

        # Creates a temporary variable with an unused name.
        def create_temporary
          @temporary_counter += 1
          Bindings::TemporaryBinding.new(current_temporary, nil)
        end
        
        # Adds a simple instruction to the current basic block.
        def add_instruction(*args)
          @current_block << args
        end
        
        # Creates the given number of blocks.
        def create_blocks(count)
          (0...count).to_a.map { create_block }
        end

        # Creates a new basic block for flow analysis.
        def create_block(name = 'B' + (@block_counter += 1).to_s)
          BasicBlock.new(name).tap { |block| @graph.add_vertex block }
        end
        
        # Sets the current block to be the given block.
        def start_block(block)
          @current_block = block
        end
      end
    end
  end
end