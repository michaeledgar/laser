# dominators.rb
#
# This file contains algorithms for finding the dominators and dominance
# frontier of a control flow graph. These algorithms require that every node
# be reachable from the start node. Keep this in mind.
require 'set'
require 'laser/third_party/rgl/traversal'

module RGL
  module Graph
    # Returns the dominator tree of the graph. O(V^2), but performs better than
    # or close to Lengauer-Tarjan on real-world ASTs.
    #
    # If the start node is not provided, it is assumed the receiver is a
    # ControlFlowGraph and has an #enter method.
    def dominator_tree(start_node = self.enter)
      doms = {start_node => start_node}
      changed = true
      reverse_postorder = compute_post_order(self, start_node)
      while changed
        changed = false
        reverse_postorder.each do |b|
          pred = b.predecessors
          original = pred.find { |node| doms[node] }
          if original
            new_idom = original
            pred.each do |p|
              if doms[p] && p != original
                new_idom = dominator_set_intersect(p, new_idom, doms) 
              end
            end
            if doms[b] != new_idom
              doms[b] = new_idom
              changed = true
            end
          end
        end
      end

      # doms is IDOM. All outward edges connect an IDom to its dominee.
      d_tree = self.class.new
      (vertices - [enter, exit]).each { |b| d_tree.add_vertex(b.dup.clear_edges) }
      doms.each { |src, dest| d_tree.add_edge(src, dest) unless src == enter && dest == enter }
      d_tree
    end

    # Returns the dominance frontier of the graph.
    #
    # If the start node is not provided, it is assumed the receiver is a
    # ControlFlowGraph and has an #enter method.
    #
    # return: Node => Set<Node>
    def dominance_frontier(start_node = self.enter, dominator_tree)
      vertices.inject(Hash.new { |h, k| h[k] = Set.new }) do |result, b|
        if b.predecessors.size >= 2
          b.predecessors.each do |p|
            b_dominator = dominator_tree[b].successors.first
            break unless b_dominator
            runner = p
            while runner && runner != b_dominator
              result[runner] << b
              runner = dominator_tree[runner].successors.first
            end
          end
        end
        result
      end
    end
    
    # Computes DF^+: the iterated dominance frontier of a set of blocks.
    # Used in SSA conversion.
    def iterated_dominance_frontier(set)
      #pp set
      worklist = Set.new(set)
      result = Set.new(set)
      frontier = dominance_frontier(dominator_tree)

      #pp frontier

      until worklist.empty?
        block = worklist.pop
        frontier[block].each do |candidate|
          unless result.include?(candidate)
            result << candidate
            worklist << candidate
          end
        end
      end
      result
    end

   private

    # performs a set intersection of the dominator tree.
    def dominator_set_intersect(b1, b2, doms)
      finger1, finger2 = b1, b2
      while finger1.post_order_number != finger2.post_order_number
        finger1 = doms[finger1] while finger1.post_order_number < finger2.post_order_number
        finger2 = doms[finger2] while finger2.post_order_number < finger1.post_order_number
      end
      finger1
    end
    
    # Good idea: depth-first ordering. found some slides about it:
    # http://pages.cs.wisc.edu/~fischer/cs701.f08/lectures/Lecture18.4up.pdf
    def compute_post_order(graph, start_node)
      i = 1
      result = []
      visited = Set.new
      post_order_df = proc do |node|
        visited << node
        graph.each_adjacent(node) do |successor|
          post_order_df.call(successor) unless visited.include?(successor)
        end
        result << node
        node.post_order_number = i
        i += 1
      end
      post_order_df.call(start_node)
      result
    end
  end
end