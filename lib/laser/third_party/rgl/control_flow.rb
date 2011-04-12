require 'laser/third_party/rgl/mutable'
require 'set'

module RGL
  # This is an implementation of a more efficient graph customized
  # for control-flow purposes. Lots of operations on RGL's base library,
  # while re-using a lot of code, are needlessly algorithmically insufficient.
  # (#empty is O(|V|)!)
  class ControlFlowGraph    
    EDGE_NORMAL = 0
    EDGE_ABNORMAL = 1 << 0
    EDGE_FAKE = 1 << 1
    EDGE_EXECUTABLE = 1 << 2

    include Enumerable
    include MutableGraph
    attr_reader :enter, :exit
    attr_reader :vertices
    
    def initialize
      @edge_flags = Hash.new { |hash, key| hash[key] = EDGE_NORMAL }
      @enter = Laser::SexpAnalysis::ControlFlow::TerminalBasicBlock.new('Enter')
      @exit = Laser::SexpAnalysis::ControlFlow::TerminalBasicBlock.new('Exit')
      @vertices = Set[@enter, @exit]
      @vertex_lookup = {'Enter' => @enter, 'Exit' => @exit}
    end
    
    def [](key)
      @vertex_lookup[key.name]
    end

    # Gets all the edges. O(E).
    def edges
      vertices.map { |vert| vert.successors.map { |succ| [vert, succ] }}.flatten 1
    end
    
    # Enumerates the vertices. O(V).
    def each_vertex(&b)
      vertices.each(&b)
    end
    alias each each_vertex

    # Enumerates every vertex adjacent to u. O(V).
    def each_adjacent(u, &b)
      self[u].successors.each(&b)
    end
    
    # Jacked from RGL. O(E).
    def each_edge
      each_vertex { |u|
        each_adjacent(u) { |v| yield u,v }
      }
    end
    
    # Adds the vertex to the set of vertices. O(1) amortized.
    def add_vertex(u)
      @vertex_lookup[u.name] = u
      vertices << u
    end
    
    # Adds the edge to the graph. O(1) amortized.
    def add_edge(u, v, flags = EDGE_NORMAL)
      @edge_flags[[u.name, v.name]] |= flags
      self[u].successors << v
      self[v].predecessors << u
    end

    def is_abnormal?(src, dest)
      (@edge_flags[[src.name, dest.name]] & EDGE_ABNORMAL) > 0
    end
    
    def is_fake?(src, dest)
      (@edge_flags[[src.name, dest.name]] & EDGE_FAKE) > 0
    end
    
    def is_executable?(src, dest)
      (@edge_flags[[src.name, dest.name]] & EDGE_EXECUTABLE) > 0
    end
    
    def add_flag(src, dest, flag)
      @edge_flags[[src.name, dest.name]] |= flag
    end
    
    def remove_flag(src, dest, flag)
      @edge_flags[[src.name, dest.name]] &= ~flag
    end

    # Removes the vertex from the graph. O(E) amortized.
    def remove_vertex(u)
      looked_up = self[u]
      looked_up.successors.each do |succ|
        self[succ].predecessors.delete looked_up
      end
      looked_up.predecessors.each do |pred|
        self[pred].successors.delete looked_up
      end
      vertices.delete looked_up
    end
    
    # Removes the edge from the graph. O(1) amortized.
    def remove_edge(u, v)
      looked_up_u, looked_up_v = @vertex_lookup[u], @vertex_lookup[v]
      looked_up_u.successors.delete(looked_up_v)
      looked_up_v.predecessors.delete(looked_up_u)
      @edge_flags.delete([u.name, v.name])
    end
    
    # Counts the number of vertices. O(1).
    def num_vertices
      vertices.size
    end
    alias size num_vertices
    
    # Does the graph have no vertices? O(1).
    def empty?
      vertices.empty?
    end
    
    # Does the graph contain this vertex? O(1).
    def has_vertex?(u)
      vertices.include?(u)
    end
    
    def has_edge?(u, v)
      self[u].successors.include?(v)
    end
    
    # Returns an array of vertices in this graph. O(V).
    def to_a
      vertices.to_a
    end
    
    # Is the graph directed? Yes, always.
    def directed?
      true
    end
    
    # Computes the total degree of the vertex. O(1).
    def degree(u)
      in_degree(u) + out_degree(u)
    end
    
    # What is the in-degree of the vertex u? O(1).
    def in_degree(u)
      self[u].predecessors.size
    end

    # What is the out-degree of the vertex u? O(1).
    def out_degree(u)
      self[u].successors.size
    end
    
    # How many edges are in the graph? O(V).
    def num_edges
      vertices.map { vertices.successors.size }.inject(:+)
    end
  end
end