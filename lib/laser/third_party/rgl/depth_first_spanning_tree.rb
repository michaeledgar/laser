
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
      compute_dfo(tree, start_node)
      tree
    end
    
    # builds the dfst from the start node.
    # O(|V| + |E|), just like DFS.
    def build_dfst(tree, node, visited)
      visited << node
      self.each_adjacent(node) do |other|
        unless visited.include?(other)
          tree.add_edge(node, other)
          build_dfst(tree, other, visited)
        end
      end
    end
    
    # Good idea: depth-first ordering. found some slides about it:
    # http://pages.cs.wisc.edu/~fischer/cs701.f08/lectures/Lecture18.4up.pdf
    def compute_dfo(tree, start_node)
      i = tree.vertices.size
      dfo = proc do |node|
        tree.each_adjacent(node) do |successor|
          dfo.call(successor)
        end
        node.depth_first_order = i
        i -= 1
      end
      dfo.call(start_node)
    end
  end
end