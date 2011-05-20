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
          @in_ssa = true
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
          self_binding = @root.scope.lookup('self')
          @name_stack[self_binding].push(self_binding)
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
            ssa_name_for(temp).definition = phi_node
            @all_cached_variables << ssa_name_for(temp)
          end
          # Replace current operands and note new definitions
          block.natural_instructions.each do |ins|
            new_operands = []
            ins.operands.each do |temp|
              ssa_uninitialize_fix(temp, block, ins) if ssa_name_for(temp).nil?
              ssa_name_for(temp).uses << ins
              new_operands << ssa_name_for(temp)
            end
            if ins.block_operand
              new_block_operand = ssa_name_for(ins.block_operand)
              new_block_operand.uses << ins
              ins.replace_block_operand(new_block_operand)
            end
            ins.replace_operands(new_operands) unless ins.operands.empty?
            ins.explicit_targets.each do |temp|
              @name_stack[temp].push(new_ssa_name(temp))
              ssa_name_for(temp).definition = ins
              @all_cached_variables << ssa_name_for(temp)
            end
          end
          # Update all phi nodes this block leads to with the name of
          # the variable this block uses
          # TODO(adgar): make ordering more reliable, it currently relies
          #   on the fact that Set uses Hash, and Hashes in 1.9 are ordered
          block.real_successors.each do |succ|
            j = succ.real_predecessors.to_a.index(block)
            phi_nodes_with_undefined_ops = succ.phi_nodes.select do |phi_node|
              ssa_name_for(phi_node[j+2]).nil?
            end
            if phi_nodes_with_undefined_ops.any?
              fixup_block = ssa_phinode_fixup_block(succ, j)
              phi_nodes_with_undefined_ops.each do |phi_node|
                assign = ssa_uninitialize_fixing_instruction(
                    phi_node[1], phi_node, fixup_block, true)
                fixup_block << assign
              end
              fixup_block << Instruction.new([:jump, succ.name], node: nil, block: fixup_block)
            end
            succ.phi_nodes.each do |phi_node|
              replacement = ssa_name_for(phi_node[j + 2])
              phi_node[j + 2] = replacement
              replacement.uses << phi_node
            end
            phi_nodes_with_undefined_ops.each do |phi_node|
              @name_stack[phi_node[1]].pop
            end
          end
          # Recurse to dominated blocks
          dom_tree[block].real_predecessors.each do |pred|
            rename_for_ssa(pred, dom_tree)
          end
          # Update all targets with the current definition
          block.natural_instructions.reverse_each do |ins|
            ins.explicit_targets.each do |target|
              ins.replace_target(target, @name_stack[target].pop)
            end
          end

          block.phi_nodes.each do |ins|
            ins[1] = @name_stack[ins[1]].pop
          end
        end

        def ssa_phinode_fixup_block(block, index)
          fixup_block = BasicBlock.new("SSA-FIX-#{block.name}-#{index}")
          add_vertex(fixup_block)

          predecessor = block.real_predecessors.to_a[index]

          fixup_block.predecessors = Set[ predecessor ]
          fixup_block.successors = Set[ block ]

          predecessor.remove_successor block
          predecessor.successors << fixup_block

          jump_insn = predecessor.last
          if jump_insn && jump_insn.type == :jump
            jump_insn[1] = fixup_block.name
          elsif jump_insn && jump_insn.type == :branch
            jump_insn[jump_insn.index(block.name)] = fixup_block.name
          end

          new_predecessors = block.predecessors.to_a
          new_predecessors[index] = fixup_block
          block.predecessors = Set.new(new_predecessors)

          fixup_block
        end

        # If a block uses a variable in a non-phi instruction, but there
        # is no name for that variable on the current path, then it is
        # being read before it has been written. Uninitialized variables
        # have value nil, so before the read, insert an assignment to
        # nil. SSA will take over from there.
        def ssa_uninitialize_fix(temp, block, ins)
          assignment = ssa_uninitialize_fixing_instruction(temp, ins, block)
          block.insert(block.index(ins), assignment)
        end

        def ssa_uninitialize_fixing_instruction(temp, reading_ins, block, renamed=false)
          @name_stack[temp].push(new_ssa_name(temp))
          @all_cached_variables << ssa_name_for(temp)
          target = renamed ? ssa_name_for(temp) : temp
          assignment = Instruction.new([:assign, target, nil],
              node: reading_ins.node, block: block)
          ssa_name_for(temp).definition = assignment
        end

        def ssa_name_for(temp)
          @name_stack[temp].last
        end
        
        def new_ssa_name(temp)
          @name_count[temp] += 1
          name = "#{temp.name}##{@name_count[temp]}"
          result = Bindings::TemporaryBinding.new(name, nil)
          if temp == @final_return
            @final_return = result
          elsif temp == @final_exception
            @final_exception = result
          elsif temp == @block_register
            @block_register = result
          end
          result
        end
      end
    end
  end
end
