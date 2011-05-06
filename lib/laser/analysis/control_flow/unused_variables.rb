module Laser
  module SexpAnalysis
    module ControlFlow
      # Finds unused variables in the control-flow graph. See thesis for
      # the algorithm and proof of correctness.
      module UnusedVariables
        IGNORED_VARS = Set.new(%w(self t#current_exception t#current_block t#exit_exception $!))
        
        # Adds unused variable warnings to all nodes which define a variable
        # that is not used.
        def add_unused_variable_warnings
          unused_variables.reject { |var| var.name.start_with?('%') }.each do |temp|
            # TODO(adgar): KILLMESOON
            next unless @definition[temp] && @definition[temp].node
            next if IGNORED_VARS.include?(temp.non_ssa_name)
            node = @definition[temp].node
            node.add_error(
                UnusedVariableWarning.new("Variable defined but not used: #{temp.non_ssa_name}", node))
          end
        end
        
        # Finds the simply-unused variables: those which are defined and never
        # read.
        def simple_unused
          variables = self.all_variables
          result = variables.dup
          variables.each do |var|
            defn = @definition[var]
            if defn.node.nil? || defn.node.reachable
              @uses[var].each do |use|
                if use.node.nil? || use.node.reachable
                  result.delete var
                else
                  @uses[var].delete use
                end
              end
            else
              @uses[var].clear
            end
          end
          result
        end
        
        # Gets the set of unused variables. After SSA transformation, any
        # variable with no uses need not be assigned. If the definition of
        # that variable can be killed, then we remove that definition as a
        # use of all its operands. This may result in further dead variables!
        # N = number of vars
        # O(N)
        def unused_variables
          worklist = Set.new(simple_unused())
          all_unused = Set.new
          while worklist.any?
            var = worklist.pop
            all_unused << var
            definition = @definition[var]
            if killable_with_unused_target?(definition)
              definition.operands.each do |op|
                next if op.name == 'self'
                use_set = @uses[op]
                use_set = use_set - [definition]
                worklist << op if use_set.empty?
              end
            end
          end
          all_unused
        end
        
        def killable_with_unused_target?(insn)
          case insn.type
          when :assign, :phi, :lambda
            true
          when :call, :call_vararg
            recv = insn[2]
            if Bindings::ConstantBinding === insn[2]
              true
            elsif insn[2].value == ControlFlow::UNDEFINED
              true
            else
              insn[2].expr_type.matching_methods(insn[3].to_s).all?(&:pure)
            end
          else
            false
          end
        end
      end
    end  # ControlFlow
  end  # SexpAnalysis
end  #