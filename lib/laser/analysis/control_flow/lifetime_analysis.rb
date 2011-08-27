module Laser
  module Analysis
    module ControlFlow
      # Methods for computing the lifetime of the variables in
      # the control flow graph.
      module LifetimeAnalysis
        # Calculates Live for all global temps. Also calculates LiveOut.
        # p.136 Morgan
        def calculate_live
          setup_lifetime
          visit = Set.new
          @live_out = Hash.new { |hash, key| hash[key] = Set.new }
          @live.clear
          @globals.each do |temp|
            @live[temp] = live_worklist(temp)
            visit.clear
            @definition_blocks[temp].each do |eval_block|
              find_live_visited(eval_block, visit, @live[temp])
            end

            @live[temp] &= visit
            @live[temp].each do |block|
              block.real_predecessors.each do |pred|
                if visit.include?(pred)
                  @live_out[pred] << temp
                end
              end
            end
          end
        end

       private

        # Computes LiveIn(T) forall Temps, Globals, and LiveKill(B) forall Blocks
        # p.134, Morgan
        def setup_lifetime
          @globals = Set.new
          exposed = Set.new
          @live_in = Hash.new { |hash, key| hash[key] = Set.new }
          @live_kill = Hash.new { |hash, key| hash[key] = Set.new }
          @definition_blocks = Hash.new { |hash, key| hash[key] = Set.new }

          vertices.each do |block|
            exposed.clear
            block.instructions.reverse_each do |ins|
              targets = ins.explicit_targets
              targets.each { |target| @definition_blocks[target] << block }
              @live_kill[block] |= targets
              exposed = (exposed - targets) | ins.operands
              exposed << ins.block_operand if ins.block_operand
            end
            @globals |= exposed
            exposed.each do |temp|
              @live_in[temp] << block
            end
          end
        end

        # Computes the set of blocks in which the given temporary is alive at
        # the beginning of the block. Uses setup_lifetime.
        # p.134, Morgan
        def live_worklist(temp)
          worklist = Set.new(@live_in[temp])
          result_live = Set.new(@live_in[temp])
          until worklist.empty?
            block = worklist.pop
            block.real_predecessors.each do |pred|
              if !@live_kill[pred].include?(temp) and !result_live.include?(pred)
                result_live << pred
                worklist << pred
              end
            end
          end
          result_live
        end

        # DFSes but ignores non-live blocks. Adds each block that is walked
        # to the visit set. Used by calculate_live.
        def find_live_visited(current, visit, live)
          visit << current
          current.real_successors.each do |block|
            if live.include?(block) && !visit.include?(block)
              find_live_visited(block, visit, live)
            end
          end
        end

      end  # module LifetimeAnalysis
    end  # module ControlFlow
  end  # module Analysis
end  # module Laser
