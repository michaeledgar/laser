require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SexpAnalysis::Visitor do
  before do
    @class = Class.new do
      include SexpAnalysis::Visitor
      def visit_foo(node)
        node.visited = node[1]
      end
      def visit_bar(node)
        node.product = node[1] * node[2]
      end
    end
  end
  
  context '#visit' do
    it 'runs the matching method when one is defined' do
      a = SexpAnalysis::Sexp.new([:foo, true])
      a.should_receive(:visited=).with(true)
      @class.new.visit(a)
      b = SexpAnalysis::Sexp.new([:bar, 3, 2])
      b.should_receive(:product=).with(6)
      @class.new.visit(b)
    end
    
    it 'automatically DFSs the tree to visit nodes when they are not handled' do
      a = SexpAnalysis::Sexp.new([:a, [:b, [:foo, false], 2, 3], [:c, [:bar, 19, 22], [:bar, 23, 2]]])
      a[1][1].should_receive(:visited=).with(false)
      a[2][1].should_receive(:product=).with(19 * 22)
      a[2][2].should_receive(:product=).with(46)
      @class.new.visit(a)
    end
  end
end