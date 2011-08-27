
# connected_components.rb
#
# This file contains the algorithms for the connected components of an
# undirected graph (each_connected_component) and strongly connected components
# for directed graphs (strongly_connected_components).
#
require 'set'
require 'laser/third_party/rgl/traversal'

module RGL
  module Graph
    # Computes the depth first spanning tree of the CFG, and
    # also attaches the depth-first ordering to the basic blocks
    # in the CFG.
    # O(|V| + |E|), just like DFS.
    def depth_first_spanning_tree(start_node)
      raise ArgumentError unless vertices.include?(start_node)
      tree = DirectedAdjacencyGraph.new
      visited = Set.new
      build_dfst(tree, start_node, visited)
      tree
    end
    
    # builds the dfst from the start node.
    # O(|V| + |E|), just like DFS.
    def build_dfst(tree, node, visited)
      visited << node
      node.real_successors.each do |other|
        if !visited.include?(other)
          tree.add_edge(node, other)
          build_dfst(tree, other, visited)
        end
      end
    end
  end
end
