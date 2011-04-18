module Laser
  module SexpAnalysis
    module ControlFlow
      # Methods for computing the static single assignment form of a
      # Control Flow Graph.
      module StaticSingleAssignment
        # SSA Form
        def static_single_assignment_form
          calculate_live
          place_phi_nodes
          ssa_name_formals
          dom_tree = dominator_tree
          rename_for_ssa(enter, dom_tree)
          self
        end
        
      private
       
        # Places phi nodes, minimally, using DF+
        def place_phi_nodes
          @globals.each do |temp|
            set = @definition_blocks[temp] | Set[enter]
            iterated_dominance_frontier(set).each do |block|
              if @live[temp].include?(block)
                n = block.real_predecessors.size
                block.unshift(Instruction.new([:phi, temp, *([temp] * n)], :block => block))
              end
            end
          end
        end
        
        # Sets up SSA to handle the formal arguments
        def ssa_name_formals
          @formal_map = {}
          self_binding = @root.scope.lookup('self')
          @name_stack[self_binding].push(self_binding)
          @formal_map[self_binding] = self_binding
          @formals.each do |formal|
            initial_formal = new_ssa_name(formal)
            @name_stack[formal].push(initial_formal)
            @formal_map[formal] = initial_formal  # store very first binding
            @definition[initial_formal] =
              Instruction.new([:param, initial_formal, formal], 
                              :node => formal.ast_node, :block => @enter)
            ssa_name_for(formal).inferred_type = formal.expr_type
          end
        end

        # Renames all variables in the block, and all blocks it dominates,
        # to SSA-form variables by adding a suffix of the form #\d. Since
        # '#' is not allowed in an identifier's name, it will be clear
        # visually what part of the name is the SSA suffix, and it is trivially
        # stripped algorithmically to determine which original temp it refers to.
        #
        # p.175, Morgan
        def rename_for_ssa(block, dom_tree)
          # Note the definition caused by all phi nodes in the block, as
          # phi nodes are evaluated immediately upon entering a block.
          block.phi_nodes.each do |phi_node|
            temp = phi_node[1]
            @name_stack[temp].push(new_ssa_name(temp))
            @definition[ssa_name_for(temp)] = phi_node
          end
          # Replace current operands and note new definitions
          block.reject { |ins| ins[0] == :phi }.each do |ins|
            new_operands = []
            ins.operands.each do |temp|
              @uses[ssa_name_for(temp)] << ins
              new_operands << ssa_name_for(temp)
            end
            ins.replace_operands(new_operands) unless ins.operands.empty?
            ins.explicit_targets.each do |temp|
              @name_stack[temp].push(new_ssa_name(temp))
              @definition[ssa_name_for(temp)] = ins
            end
          end
          # Update all phi nodes this block leads to with the name of
          # the variable this block uses
          # TODO(adgar): make ordering more reliable
          block.real_successors.each do |succ|
            j = succ.real_predecessors.to_a.index(block)
            succ.phi_nodes.each do |phi_node|
              replacement = ssa_name_for(phi_node[j + 2])
              phi_node[j + 2] = replacement
              @uses[replacement] << phi_node
            end
          end
          # Recurse to dominated blocks
          dom_tree.vertex_with_name(block.name).real_predecessors.each do |pred|
            rename_for_ssa(pred, dom_tree)
          end
          # Update all targets with the current definition
          block.reject { |ins| ins[0] == :phi }.reverse_each do |ins|
            ins.explicit_targets.each do |target|
              ins.replace_target(target, @name_stack[target].pop)
            end
          end
          block.phi_nodes.each do |ins|
            ins[1] = @name_stack[ins[1]].pop
          end
        end
        
        def ssa_name_for(temp)
          if @name_stack[temp].empty?
            # variable undefined here due to dead code.
            new_ssa_name(temp, true)
          else
            @name_stack[temp].last
          end
        end
        
        def new_ssa_name(temp, undefined=false)
          @name_count[temp] += 1
          name = "#{temp.name}##{@name_count[temp]}"
          name << '_undef' if undefined
          Bindings::TemporaryBinding.new(name, nil)
        end
      end
    end
  end
end