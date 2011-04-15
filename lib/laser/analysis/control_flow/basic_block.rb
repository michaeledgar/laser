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
        
        def equal?(other)
          name == other.name
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
          instructions.empty? || instructions.last.type == :call
        end

        # Formats the block all pretty-like for Graphviz. Horrible formatting for
        # stdout.
        def to_s
          " | #{name} | \\n" + instructions.map do |ins|
            opcode = ins.first.to_s
            args = ins[1..-1].map do |arg|
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