require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ControlFlow::GraphBuilder do
  describe 'when empty' do
    it 'should create the entry and exit blocks, returning nil, with an edge between them' do
      # 1-0-3 skips :program, a list, and the :def
      tree = annotate_all('def CFG_T1(x); end')[1][0][3]
      first_block = ControlFlow::BasicBlock.new('Enter')
      first_block << [:assign, t1 = Bindings::TemporaryBinding.new('%t1', nil), nil]
      first_block << [:return, t1]
      first_block << [:jump, 'Exit']
      last_block = ControlFlow::BasicBlock.new('Exit')
      expected_tree = ControlFlow::ControlFlowGraph[first_block, last_block]
      expected_tree.add_vertex(ControlFlow::BasicBlock.new('Dead Code'))
      ControlFlow::GraphBuilder.new(tree).build.should == expected_tree
    end
  end
  
  describe 'with a constant as the final value' do
    it 'should return that constant value' do
      cfg = ControlFlow::GraphBuilder.new(
          annotate_all('def CFG_T1(x); 3.14; end')[1][0][3]).build
      list = cfg.vertex_with_name('Enter').instructions[-3..-1]
      list.should == [
        [:assign, t1 = Bindings::TemporaryBinding.new('%t1', nil), 3.14],
        [:return, t1],
        [:jump, 'Exit']]
    end
  end
end