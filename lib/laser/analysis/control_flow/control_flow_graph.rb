require 'laser/third_party/rgl/adjacency'
require 'laser/third_party/rgl/transitivity'
module Laser
  module SexpAnalysis
    module ControlFlow
      class ControlFlowGraph < RGL::DirectedAdjacencyGraph
        attr_accessor :enter, :exit, :root
        def initialize(*args)
          @abnormals = Set.new
          super
        end
        # Compares the graphs for equality. Relies on the basic blocks having unique
        # names to simplify isomorphism comparisons. Unfortunately this means
        # tests will have to know block names. Oh well.
        def ==(other)
          pairs = self.vertices.sort_by(&:name).zip(other.vertices.sort_by(&:name))
          (pairs.all? do |v1, v2|
            v1.name.should == v2.name && v1.instructions.should == v2.instructions
          end) && (self.edges.sort.should == other.edges.sort)
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
        
        def add_abnormal_edge(src, dest)
          @abnormals << [src.name, dest.name]
          add_edge src, dest
        end
        
        def is_abnormal?(src, dest)
          @abnormals.include?([src.name, dest.name])
        end
        
        def remove_abnormal_edge(src, dest)
          @abnormals.delete([src.name, dest.name])
          remove_edge src, dest
        end
        
        # Dead code discovery first. Just warnings.
        def analyze
          perform_dead_code_discovery
        end
        
        def all_errors
          self.root.all_errors
        end
        
        # Dead Code Discovery: O(|V||E|)!
        IGNORED_DEAD_CODE_NODES = [:@ident, :@op, :void_stmt]
        def perform_dead_code_discovery
          # O(|V||E|)
          tc = self.transitive_closure
          # first, set all to reachable. O(V+E)
          self.root.dfs { |x| x.reachable = true if Sexp === x }
          # then, go over all code in dead blocks, and mark potentially dead
          # ast nodes.
          # O(V)
          (tc.vertices - tc.adjacent_vertices(@enter)).each do |blk|
            blk.each { |ins| ins.node.reachable = false }
          end
          # run through all reachable statements and mark those nodes, and their
          # parents, as partially executing.
          #
          # at most |V| nodes will have cur.reachable = true set.
          # at most O(V) instructions will be visited total.
          tc.each_adjacent(@enter) do |blk|
            blk.instructions.each do |ins|
              cur = ins.node
              while cur && !cur.reachable
                cur.reachable = true
                cur = cur.parent
              end
            end
          end
          dfs_for_dead_code self.root
        end
        
        def dfs_for_dead_code(node)
          if node.reachable
            node.children.select { |x| Sexp === x }.reject do |child|
              child == [] || child[0].is_a?(::Fixnum) || IGNORED_DEAD_CODE_NODES.include?(child.type)
            end.each do |child|
              dfs_for_dead_code(child)
            end
          else
            node.errors << DeadCodeWarning.new('Dead code', node)
          end
        end
      end
    end
  end
end