require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ControlFlow::ControlFlowGraph do
  describe '#vertex_with_name' do
    it 'looks up blocks by name in the graph' do
      g = ControlFlow::ControlFlowGraph.new
      g.vertex_with_name('Enter').should == g.enter
      g.vertex_with_name('Exit').should == g.exit

    end
  end
end