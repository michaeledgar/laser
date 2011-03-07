require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ControlFlow::ControlFlowGraph do
  describe '#vertex_with_name' do
    it 'looks up blocks by name in the graph' do
      # 1-0-3 skips :program, a list, and the :def
      tree = annotate_all('def CFG_T1(x); end')[1][0][3]
      first_block = ControlFlow::BasicBlock.new('Enter')
      first_block << [:assign, t1 = Bindings::TemporaryBinding.new('%t1', nil), nil]
      first_block << [:return, t1]
      first_block << [:jump, 'Exit']
      last_block = ControlFlow::BasicBlock.new('Exit')
      dead_code = ControlFlow::BasicBlock.new('Dead Code')
      expected_tree = ControlFlow::ControlFlowGraph[first_block, last_block]
      expected_tree.add_vertex(dead_code)
      
      expected_tree.vertex_with_name('Enter').should == first_block
      expected_tree.vertex_with_name('Exit').should == last_block
      expected_tree.vertex_with_name('Dead Code').should == dead_code
    end
  end
end