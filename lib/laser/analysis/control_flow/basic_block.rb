require 'set'
module Laser
  module SexpAnalysis
    module ControlFlow
      # Can't use the < DelegateClass(Array) syntax because of code reloading.
      class BasicBlock < BasicObject
        attr_accessor :name, :instructions, :successors, :predecessors
        attr_accessor :depth_first_order, :post_order_number
        def initialize(name)
          @name = name
          @instructions = []
          @successors = ::Set.new
          @predecessors = ::Set.new
          @edge_flags = ::Hash.new { |hash, key| hash[key] = ::RGL::ControlFlowGraph::EDGE_NORMAL }
        end

        # Duplicates the block, but *not* the instructions, as that's likely
        # just a waste of memory.
        def dup
          result = BasicBlock.new(name)
          result.instructions = instructions
          result.successors = successors.dup
          result.predecessors = predecessors.dup
          result
        end
        
        def duplicate_for_graph_copy(temp_lookup, insn_lookup)
          result = BasicBlock.new(name)
          result.instructions = instructions.map do |insn|
            copy = insn.deep_dup(temp_lookup, block: result)
            insn_lookup[insn] = copy
            copy
          end
          # successors/predecessors will be inserted by graph copy.
          result
        end

        def get_flags(dest)
          @edge_flags[dest.name]
        end

        def has_flag?(dest, flag)
          (get_flags(dest) & flag) > 0
        end

        def add_flag(dest, flag)
          @edge_flags[dest.name] |= flag
        end

        def set_flag(dest, flag)
          @edge_flags[dest.name] = flag
        end

        def remove_flag(dest, flag)
          @edge_flags[dest.name] &= ~flag
        end
        
        def delete_all_flags(dest)
          @edge_flags.delete dest.name
        end
        
        def is_fake?(dest)
          has_flag?(dest, ::RGL::ControlFlowGraph::EDGE_FAKE)
        end
        
        def is_executable?(dest)
          has_flag?(dest, ::RGL::ControlFlowGraph::EDGE_EXECUTABLE)
        end

        def real_successors
          successors.reject { |dest| has_flag?(dest, ::RGL::ControlFlowGraph::EDGE_FAKE) }
        end

        def real_predecessors
          predecessors.reject { |dest| dest.has_flag?(self, ::RGL::ControlFlowGraph::EDGE_FAKE) }
        end
        
        def normal_successors
          successors.reject { |dest| has_flag?(dest, ::RGL::ControlFlowGraph::EDGE_ABNORMAL) }
        end

        def normal_predecessors
          predecessors.reject { |dest| dest.has_flag?(self, ::RGL::ControlFlowGraph::EDGE_ABNORMAL) }
        end

        def abnormal_successors
          successors.select { |dest| has_flag?(dest, ::RGL::ControlFlowGraph::EDGE_ABNORMAL) }
        end

        def abnormal_predecessors
          predecessors.select { |dest| dest.has_flag?(self, ::RGL::ControlFlowGraph::EDGE_ABNORMAL) }
        end

        def executed_successors
          successors.select { |dest| has_flag?(dest, ::RGL::ControlFlowGraph::EDGE_EXECUTABLE) }
        end

        def executed_predecessors
          predecessors.select { |dest| dest.has_flag?(self, ::RGL::ControlFlowGraph::EDGE_EXECUTABLE) }
        end

        def unexecuted_successors
          successors.reject { |dest| has_flag?(dest, ::RGL::ControlFlowGraph::EDGE_EXECUTABLE) }
        end

        def unexecuted_predecessors
          predecessors.reject { |dest| dest.has_flag?(self, ::RGL::ControlFlowGraph::EDGE_EXECUTABLE) }
        end

        # Removes all edges from this block.
        def clear_edges
          @successors.clear
          @predecessors.clear
          self
        end

        def eql?(other)
          self == other
        end

        def ==(other)
          equal?(other) || name == other.name
        end
        
        def !=(other)
          !(self == other)
        end

        def hash
          name.hash
        end

        def variables
          ::Set.new(instructions.map(&:explicit_targets).inject(:|))
        end
        
        # Gets all SSA Phi nodes that are in the block.
        def phi_nodes
          instructions.select { |ins| :phi == ins[0] }
        end
        
        def natural_instructions
          instructions.reject { |ins| :phi == ins[0] }
        end

        def fall_through_block?
          instructions.empty?# || instructions.last.type == :call
        end

        def remove_successor(u)
          successors.delete u
        end

        def remove_predecessor(u)
          last_insn = u.instructions.last
          if last_insn.type == :branch
            which_to_keep = last_insn[3] == self.name ? last_insn[2] : last_insn[3]
            last_insn[1].uses.delete last_insn
            last_insn.body.replace([:jump, which_to_keep])
          end
          # must update phi nodes.
          which_phi_arg = predecessors.to_a.index(u) + 2
          phi_nodes.each do |node|
            node.delete_at(which_phi_arg)
            if node.size == 3
              node.replace([:assign, node[1], node[2]])
            end
          end
          predecessors.delete u
        end

        # Formats the block all pretty-like for Graphviz. Horrible formatting for
        # stdout.
        def to_s
          " | #{name} | \\n" + instructions.map do |ins|
            opcode = ins.first.to_s
            if ins.method_call? && ::Hash === ins.last
            then range = 1..-2
            else range = 1..-1
            end
            args = ins[range].map do |arg|
              if Bindings::GenericBinding === arg
              then arg.name
              else arg.inspect
              end
            end
            [opcode, *args].join(', ')
          end.join('\\n')
        end

        # Proxies all other methods to the instruction list.
        def method_missing(meth, *args, &blk)
          @instructions.send(meth, *args, &blk)
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
