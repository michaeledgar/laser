require 'enumerator'
require 'set'
module Laser
  module Analysis
    module ControlFlow
      # Can't use the < DelegateClass(Array) syntax because of code reloading.
      class BasicBlock
        def duplicate_for_graph_copy(temp_lookup, insn_lookup)
          result = BasicBlock.new(name)
          instructions.each do |insn|
            copy = insn.deep_dup(temp_lookup, block: result)
            insn_lookup[insn] = copy
            result.instructions << copy
            copy
          end
          # successors/predecessors will be inserted by graph copy.
          result
        end
        
        def is_fake?(dest)
          has_flag?(dest, RGL::ControlFlowGraph::EDGE_FAKE)
        end
        
        def is_executable?(dest)
          has_flag?(dest, RGL::ControlFlowGraph::EDGE_EXECUTABLE)
        end

        def real_successors
          successors.reject { |dest| has_flag?(dest, RGL::ControlFlowGraph::EDGE_FAKE) }
        end
        
        def normal_successors
          successors.reject { |dest| has_flag?(dest, RGL::ControlFlowGraph::EDGE_ABNORMAL) }
        end

        def variables
          Set.new(instructions.map(&:explicit_targets).inject(:|))
        end
        
        # Gets all SSA Phi nodes that are in the block.
        def phi_nodes
          instructions.select { |ins| :phi == ins[0] }
        end
        
        def natural_instructions
          instructions.reject { |ins| :phi == ins[0] }
        end

        def fall_through_block?
          instructions.empty?
        end

        alias_method :disconnect_without_fixup, :disconnect

        def disconnect(dest)
          last_insn = instructions.last
          if last_insn.type == :branch
            which_to_keep = last_insn[3] == dest.name ? last_insn[2] : last_insn[3]
            last_insn[1].uses.delete last_insn
            last_insn.body.replace([:jump, which_to_keep])
          end
          # must update phi nodes.
          unless dest.phi_nodes.empty?
            which_phi_arg = dest.predecessors.to_a.index(self) + 2
            dest.phi_nodes.each do |node|
              node.delete_at(which_phi_arg)
              if node.size == 3
                node.replace([:assign, node[1], node[2]])
              end
            end
          end
          disconnect_without_fixup(dest)
        end

        # Formats the block all pretty-like for Graphviz. Horrible formatting for
        # stdout.
        def to_s
          " | #{name} | \\n" + instructions.map do |ins|
            opcode = ins.first.to_s
            if ins.method_call? && Hash === ins.last
            then range = 1..-2
            else range = 1..-1
            end
            args = ins[range].map do |arg|
              if Bindings::Base === arg
              then arg.name
              else arg.inspect
              end
            end
            if ::Hash === ins.last && ins.last[:block]
              args << {block: ins.last[:block]}
            end
            [opcode, *args].join(', ')
          end.join('\\n')
        end
      end
      
      class TerminalBasicBlock < BasicBlock
        def instructions
          []
        end
      end
    end
  end
end