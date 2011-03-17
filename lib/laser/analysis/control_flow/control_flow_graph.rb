require 'laser/third_party/rgl/adjacency'
module Laser
  module SexpAnalysis
    module ControlFlow
      class ControlFlowGraph < RGL::DirectedAdjacencyGraph
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
      end
    end
  end
end