# dot.rb
#
# $Id: dot.rb,v 1.8 2008/08/26 20:07:09 javanthropus Exp $
#
# Minimal Dot support, based on Dave Thomas's dot module (included in rdoc).
# rdot.rb is a modified version which also contains support for undirected
# graphs.

require 'laser/third_party/rgl/rdot'

module RGL

  module Graph

    # Return a RGL::DOT::Digraph for directed graphs or a DOT::Subgraph for an
    # undirected Graph.  _params_ can contain any graph property specified in
    # rdot.rb.

    def to_dot_graph (params = {})
      params['name'] ||= self.class.name.gsub(/:/,'_')
      fontsize   = params['fontsize'] || '8'
      fontname   = params['fontname'] || 'Times-Roman'
      graph      = (directed? ? DOT::Digraph : DOT::Subgraph).new(params)
      edge_class = directed? ? DOT::DirectedEdge : DOT::Edge
      shape = params['shape'] || 'ellipse'
      each_vertex do |v|
        name = v.to_s
        graph << DOT::Node.new('name'     => name,
                               'fontsize' => fontsize,
                               'label'    => name,
                               'shape'    => shape,
                               'fontname' => fontname)
      end
      each_edge do |u,v|
        if respond_to?(:is_abnormal?)
          if is_abnormal?(u, v) && is_block_taken?(u, v)
            color = 'blue'
          elsif is_abnormal?(u, v)
            color = 'red'
          elsif is_fake?(u, v)
            color = '#bbbbbb'
          else
            color = 'black'
          end
          style = (is_fake?(u, v) || !is_executable?(u, v)) ? 'dashed' : 'solid'
        else
          color = 'black'
          style = 'solid'
        end
        graph << edge_class.new('from'     => u.to_s,
                                'to'       => v.to_s,
                                'fontsize' => fontsize,
                                'fontname' => fontname,
                                'color'    => color,
                                'style'    => style)
      end
      graph
    end

    # Output the DOT-graph to stream _s_.

    def print_dotted_on (params = {}, s = $stdout)
      s << to_dot_graph(params).to_s << "\n"
    end

    # Call dotty[http://www.graphviz.org] for the graph which is written to the
    # file 'graph.dot' in the # current directory.

    def dotty (params = {})
      dotfile = "graph.dot"
      File.open(dotfile, "w") {|f|
        print_dotted_on(params, f)
      }
      system("dotty", dotfile)
    end

    # Use dot[http://www.graphviz.org] to create a graphical representation of
    # the graph.  Returns the filename of the graphics file.

    def write_to_graphic_file (fmt='png', dotfile='graph', params = {})
      src = dotfile + ".dot"
      dot = dotfile + "." + fmt

      File.open(src, 'w') do |f|
        f << self.to_dot_graph(params).to_s << "\n"
      end

      system( "dot -T#{fmt} -o #{dot} #{src}" )
      dot
    end

  end                           # module Graph
end                             # module RGL
