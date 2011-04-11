require 'laser/third_party/rgl/adjacency'
require 'laser/third_party/rgl/transitivity'
require 'laser/third_party/rgl/dominators'
module Laser
  module SexpAnalysis
    module ControlFlow
      class ControlFlowGraph < RGL::ControlFlowGraph
        attr_accessor :root
        attr_reader :edge_flags
        def initialize(*args)
          @uses = Hash.new { |hash, temp| hash[temp] = Set.new }
          @definition = {}
          @name_stack = Hash.new { |hash, temp| hash[temp] = [] }
          @name_count = Hash.new { |hash, temp| hash[temp] = 0 }
          super
        end

        # Compares the graphs for equality. Relies on the basic blocks having unique
        # names to simplify isomorphism comparisons. Unfortunately this means
        # tests will have to know block names. Oh well.
        def ==(other)
          pairs = self.vertices.sort_by(&:name).zip(other.vertices.sort_by(&:name))
          (pairs.all? do |v1, v2|
            v1.name == v2.name && v1.instructions == v2.instructions
          end) && (self.edges.sort == other.edges.sort)
        end
        
        # Looks up the basic block (vertex) with the given name.
        def vertex_with_name(name)
          self.vertices.find { |vert| vert.name == name }
        end
        
        def save_pretty_picture(fmt='png', dotfile='graph', params = {'shape' => 'box'})
          write_to_graphic_file(fmt, dotfile, params)
        end
        
        def dotty(params = {'shape' => 'box'})
          super
        end
        
        # Runs full analysis on the CFG. Puts it in SSA then searches for warnings.
        def analyze
          static_single_assignment_form
          add_unused_variable_warnings
          perform_dead_code_discovery
        end
        
        def all_errors
          self.root.all_errors
        end

        # Variable Information
        
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
            block.predecessors.each do |pred|
              if !@live_kill[pred].include?(temp) and !result_live.include?(pred)
                result_live << pred
                worklist << pred
              end
            end
          end
          result_live
        end
        
        # Calculates Live for all global temps. Also calculates LiveOut.
        # p.136 Morgan
        def calculate_live
          setup_lifetime
          visit = Set.new
          @live_out = Hash.new { |hash, key| hash[key] = Set.new }
          @live = Hash.new { |hash, key| hash[key] = Set.new }
          @globals.each do |temp|
            @live[temp] = live_worklist(temp)
            visit.clear
            @definition_blocks[temp].each do |eval_block|
              find_live_visited(eval_block, visit, @live[temp])
            end

            @live[temp] &= visit
            @live[temp].each do |block|
              block.predecessors.each do |pred|
                if visit.include?(pred)
                  @live_out[pred] << temp
                end
              end
            end
          end
        end
        
        # DFSes but ignores non-live blocks. Adds each block that is walked
        # to the visit set. Used by calculate_live.
        def find_live_visited(current, visit, live)
          visit << current
          current.successors.each do |block|
            if live.include?(block) && !visit.include?(block)
              find_live_visited(block, visit, live)
            end
          end
        end

        # SSA Form
        def static_single_assignment_form
          # result_graph = self.class.new
          # vertices.each do |b|
          #   new_vertex = b.dup.clear_edges
          #   new_vertex.instructions = Array.new(new_vertex.instructions)
          #   result_graph.add_vertex new_vertex
          # end
          # each_edge do |u, v|
          #   result_graph.add_edge(u, v)
          # end
          # result_graph.edge_flags.replace(self.edge_flags)
          # 
          # result_graph is a semi-deep copy
          calculate_live
          @globals.each do |temp|
            set = @definition_blocks[temp] | Set[enter]
            iterated_dominance_frontier(set).each do |block|
              if @live[temp].include?(block)
                n = block.predecessors.size
                block.unshift(Instruction.new([:phi, temp, *([temp] * n)]))
              end
            end
          end
          rename_for_ssa(enter, dominator_tree)
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
          "#{temp.name}##{@name_count[temp]}"
        end
        
        # Returns the names of all variables in the graph
        def all_variables
          vertices.map(&:variables).inject(:|)
        end
        
        # Dead Code Discovery: O(|V| + |E|)!
        IGNORED_DEAD_CODE_NODES = [:@ident, :@op, :void_stmt]
        def perform_dead_code_discovery
          dfst = depth_first_spanning_tree(self.enter)
          # then, go over all code in dead blocks, and mark potentially dead
          # ast nodes.
          # O(V)
          (vertices - dfst.vertices).each do |blk|
            blk.each { |ins| ins.node.reachable = false unless ins[0] == :jump  }
          end
          # run through all reachable statements and mark those nodes, and their
          # parents, as partially executing.
          #
          # at most |V| nodes will have cur.reachable = true set.
          # at most O(V) instructions will be visited total.
          dfst.each_vertex do |blk|
            blk.instructions.each do |ins|
              cur = ins.node
              while cur
                cur.reachable = true
                cur = cur.parent
              end
            end
          end
          dfs_for_dead_code self.root
        end
        
        # Performs a simple DFS, adding errors to any nodes that are still
        # marked unreachable.
        def dfs_for_dead_code(node)
          if node.reachable
            node.children.select { |x| Sexp === x }.reject do |child|
              child == [] || child[0].is_a?(::Fixnum) || IGNORED_DEAD_CODE_NODES.include?(child.type)
            end.each do |child|
              dfs_for_dead_code(child)
            end
          else
            node.add_error DeadCodeWarning.new('Dead code', node)
          end
        end
        
        # Adds unused variable warnings to all nodes which define a variable
        # that is not used.
        def add_unused_variable_warnings
          unused_variables.reject { |var| var.start_with?('%') }.each do |temp|
            # TODO(adgar): KILLMESOON
            next unless @definition[temp]
            node = @definition[temp].node
            node.add_error(
                UnusedVariableWarning.new("Variable defined but not used: #{temp.rpartition('#').first}", node))
          end
        end
        
        # Gets the set of unused variables. After SSA transformation, any
        # variable with uses
        def unused_variables
          all_variables - @uses.keys.select { |temp| @uses[temp].any? }
        end
      end
    end
  end
end