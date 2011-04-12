module Laser
  module SexpAnalysis
    module ControlFlow
      # Methods for computing the static single assignment form of a
      # Control Flow Graph.
      module StaticSingleAssignment
        # SSA Form
        def static_single_assignment_form
          calculate_live
          @globals.each do |temp|
            set = @definition_blocks[temp] | Set[enter]
            iterated_dominance_frontier(set).each do |block|
              if @live[temp].include?(block)
                n = block.predecessors.size
                block.unshift(Instruction.new([:phi, temp, *([temp] * n)], :block => block))
              end
            end
          end
          rename_for_ssa(enter, dominator_tree)
        end
        
       private

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
          block.successors.each do |succ|
            j = succ.predecessors.to_a.index(block)
            succ.phi_nodes.each do |phi_node|
              phi_node[j + 2] = ssa_name_for(phi_node[j + 2])
              @uses[ssa_name_for(phi_node[j + 2])] << phi_node
            end
          end
          # Recurse to dominated blocks
          dom_tree.vertex_with_name(block.name).predecessors.each do |pred|
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
          @name_stack[temp].last
        end
        
        def new_ssa_name(temp)
          @name_count[temp] += 1
          Bindings::TemporaryBinding.new("#{temp.name}##{@name_count[temp]}", nil)
        end
      end
    end
  end
end