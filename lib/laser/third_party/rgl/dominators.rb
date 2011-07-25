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
          if (original = b.each_real_predecessors.find { |node| doms[node] })
            new_idom = original
            b.each_real_predecessors do |p|
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
      (vertices - [enter, exit]).each do |b|
        copy = Laser::Analysis::ControlFlow::BasicBlock.new(b.name)
        copy.instructions = b.instructions
        d_tree.add_vertex(copy)
      end
      doms.each { |src, dest| d_tree.add_edge(d_tree[src], d_tree[dest]) unless src == enter && dest == enter }
      d_tree
    end

    # Returns the dominance frontier of the graph.
    #
    # If the start node is not provided, it is assumed the receiver is a
    # ControlFlowGraph and has an #enter method.
    #
    # return: Node => Set<Node>
    def dominance_frontier(start_node = self.enter, dom_tree)
      vertices.inject(Hash.new { |h, k| h[k] = Set.new }) do |result, b|
        preds = b.real_predecessors
        if preds.size >= 2
          preds.each do |p|
            b_dominator = dom_tree[b].successors.first
            break unless b_dominator
            runner = dom_tree[p]
            while runner && runner != b_dominator
              result[runner] << b
              runner = runner.successors.first
            end
          end
        end
        result
      end
    end
    
    # Computes DF^+: the iterated dominance frontier of a set of blocks.
    # Used in SSA conversion.
    def iterated_dominance_frontier(set, dom_tree)
      worklist = Set.new(set)
      result = Set.new(set)
      frontier = dominance_frontier(dom_tree)

      until worklist.empty?
        block = worklist.pop
        frontier[dom_tree[block]].each do |candidate|
          candidate_in_full_graph = self[candidate]
          unless result.include?(candidate_in_full_graph)
            result << candidate_in_full_graph
            worklist << candidate_in_full_graph
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
        node.real_successors.each do |successor|
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