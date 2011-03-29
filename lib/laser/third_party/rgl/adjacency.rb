# adjacency.rb
# 
# $Id: adjacency.rb,v 1.12 2008/08/23 05:37:05 javanthropus Exp $
# 
# The DirectedAdjacencyGraph class implements a generalized adjacency list
# graph structure.  An AdjacencyGraph is basically a two-dimensional structure
# (ie, a list of lists).  Each element of the first dimension represents a
# vertex.  Each of the vertices contains a one-dimensional structure that is
# the list of all adjacent vertices.
#
# The class for representing the adjacency list of a vertex is, by default, a
# Set.  This can be configured by the client, however, when an AdjacencyGraph
# is created.

require 'laser/third_party/rgl/mutable'
require 'set'

module RGL
  class DirectedAdjacencyGraph

    include MutableGraph

    # Shortcut for creating a DirectedAdjacencyGraph:
    #
    #  RGL::DirectedAdjacencyGraph[1,2, 2,3, 2,4, 4,5].edges.to_a.to_s =>
    #    "(1-2)(2-3)(2-4)(4-5)"

    def self.[] (*a)
      result = new
      0.step(a.size-1, 2) { |i| result.add_edge(a[i], a[i+1]) }
      result
    end

    # Returns a new empty DirectedAdjacencyGraph which has as its edgelist
    # class the given class.  The default edgelist class is Set, to ensure
    # set semantics for edges and vertices.
    #
    # If other graphs are passed as parameters their vertices and edges are
    # added to the new graph.
    def initialize (edgelist_class = Set, *other_graphs)
      @edgelist_class = edgelist_class
      @vertex_dict   = Hash.new
      @predecessor_dict = Hash.new
      
      add_graphs(*other_graphs)
    end

    # Copy internal vertice_dict
    def initialize_copy(orig)
      @vertex_dict = orig.instance_eval{@vertex_dict}.dup
      @vertex_dict.keys.each do |v|
        @vertex_dict[v] = @vertex_dict[v].dup
      end
      @predecessor_dict = orig.instance_eval{@predecessor_dict}.dup
      @predecessor_dict.keys.each do |v|
        @predecessor_dict[v] = @predecessor_dict[v].dup
      end
    end

    # Iterator for the keys of the vertice list hash.

    def each_vertex (&b)
      @vertex_dict.each_key(&b)
    end

    def each_adjacent (v, &b)			# :nodoc:
      adjacency_list = (@vertex_dict[v] or
        raise NoVertexError, "No vertex #{v}.")
      adjacency_list.each(&b)
    end
    
    def each_predecessor(v, &b)
      predecessor_dict = (@predecessor_dict[v] or
        raise NoVertexError, "No vertex #{v}.")
      predecessor_dict.each(&b)
    end

    # Returns true.

    def directed?
      true
    end

    # Complexity is O(1), because the vertices are kept in a Hash containing
    # as values the lists of adjacent vertices of _v_.

    def has_vertex? (v)
      @vertex_dict.has_key?(v)
    end

    # Complexity is O(1), if a Set is used as adjacency list.  Otherwise,
    # complexity is O(out_degree(v)).
    #
    # ---
    # MutableGraph interface.

    def has_edge? (u, v)
      has_vertex?(u) and @vertex_dict[u].include?(v)
    end

    # See MutableGraph#add_vertex.
    #
    # If the vertex is already in the graph (using eql?), the method does
    # nothing.

    def add_vertex (v)
      @vertex_dict[v] ||= @edgelist_class.new
      @predecessor_dict[v] ||= @edgelist_class.new
    end

    # See MutableGraph#add_edge.

    def add_edge (u, v)
      add_vertex(u)                         # ensure key
      add_vertex(v)                         # ensure key
      basic_add_edge(u, v)
    end

    # See MutableGraph#remove_vertex.

    def remove_vertex (v)
      @vertex_dict.delete(v)
      @predecessor_dict.delete(v)
      # remove v from all adjacency lists

      @vertex_dict.each_value { |adjList| adjList.delete(v) }
      @predecessor_dict.each_value { |predlist| predlist.delete(v) }
    end

    # See MutableGraph::remove_edge.

    def remove_edge (u, v)
      @vertex_dict[u].delete(v) unless @vertex_dict[u].nil?
      @predecessor_dict[v].delete(u) unless @predecessor_dict[v].nil?
    end

    # Converts the adjacency list of each vertex to be of type _klass_. The
    # class is expected to have a new contructor which accepts an enumerable as
    # parameter.
    def edgelist_class=(klass)
      @vertex_dict.keys.each do |v|
        @vertex_dict[v] = klass.new @vertex_dict[v].to_a
      end
      @predecessor_dict.keys.each do |v|
        @predecessor_dict[v] = klass.new @predecessor_dict[v].to_a
      end
    end

    protected

    def basic_add_edge (u, v)
      @vertex_dict[u].add(v)
      @predecessor_dict[v].add(u)
    end

  end		# class DirectedAdjacencyGraph

  # AdjacencyGraph is an undirected Graph.  The methods add_edge and
  # remove_edge are reimplemented:  If an edge (u,v) is added or removed,
  # then the reverse edge (v,u) is also added or removed.

  class AdjacencyGraph < DirectedAdjacencyGraph 

    def directed?				# Always returns false.
      false
    end
        
    # Also removes (v,u)

    def remove_edge (u, v)
      super
      @vertex_dict[v].delete(u) unless @vertex_dict[v].nil?
    end

    protected

    def basic_add_edge (u,v)
      super
      @vertex_dict[v].add(u)			# Insert backwards edge
    end

  end		# class AdjacencyGraph

  module Graph

    # Convert a general graph to an AdjacencyGraph.  If the graph is directed,
    # returns a DirectedAdjacencyGraph; otherwise, returns an AdjacencyGraph.

    def to_adjacency
      result = (directed? ? DirectedAdjacencyGraph : AdjacencyGraph).new
      each_vertex { |v| result.add_vertex(v) }
      each_edge { |u,v| result.add_edge(u, v) }
      result
    end

    # Return a new DirectedAdjacencyGraph which has the same set of vertices.
    # If (u,v) is an edge of the graph, then (v,u) is an edge of the result.
    #
    # If the graph is undirected, the result is self.

    def reverse
      return self unless directed?
      result = DirectedAdjacencyGraph.new
      each_vertex { |v| result.add_vertex v }
      each_edge { |u,v| result.add_edge(v, u) }
      result
    end

    # Return a new AdjacencyGraph which has the same set of vertices.  If (u,v)
    # is an edge of the graph, then (u,v) and (v,u) (which are the same edges)
    # are edges of the result.
    #
    # If the graph is undirected, the result is self.

    def to_undirected
      return self unless directed?
      AdjacencyGraph.new(Set, self)
    end

  end		# module Graph
end		# module RGL
