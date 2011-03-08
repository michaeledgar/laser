require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ControlFlow::GraphBuilder do
  describe 'when empty' do
    it 'should create the entry and exit blocks, returning nil, with an edge between them' do
      # 1-0-3 skips :program, a list, and the :def
      first_block = ControlFlow::BasicBlock.new('Enter')
      first_block << [:assign, t1 = Bindings::TemporaryBinding.new('%t1', nil), nil]
      first_block << [:return, t1]
      first_block << [:jump, 'Exit']
      last_block = ControlFlow::BasicBlock.new('Exit')
      expected_tree = ControlFlow::ControlFlowGraph[first_block, last_block]
      expected_tree.add_vertex ControlFlow::BasicBlock.new('B1')
      cfg_builder_for('def CFG_T1(x); end').build.should == expected_tree
    end
  end
  
  describe 'with a constant as the final value' do
    it 'should return that constant value' do
      cfg = cfg_builder_for('def CFG_T1(x); 3.14; end').build
      list = cfg.vertex_with_name('Enter').instructions[-3..-1]
      list.should == [
        [:assign, t1 = Bindings::TemporaryBinding.new('%t1', nil), 3.14],
        [:return, t1],
        [:jump, 'Exit']]
    end
  end
  
  describe 'with an assignment' do
    it 'should include the relevant assignment instruction' do
      builder = cfg_builder_for('def CFG_T1(x); x = 3.14; 5; end')
      cfg = builder.build
      list = cfg.vertex_with_name('Enter').instructions
      t1 = Bindings::TemporaryBinding.new('%t1', nil)
      list.index([:assign, t1, 3.14]).should be <
          list.index([:assign, builder.sexp.scope.lookup('x'), t1])
    end
    
    it 'should return the temporary being assigned' do
      builder = cfg_builder_for('def CFG_T1(x); x = 3.14; end')
      cfg = builder.build
      list = cfg.vertex_with_name('Enter').instructions
      t1 = Bindings::TemporaryBinding.new('%t1', nil)
      list.index([:assign, t1, 3.14]).should be <
          list.index([:assign, builder.sexp.scope.lookup('x'), t1])
      list[-2..-1].should == [
          [:return, t1],
          [:jump, 'Exit']]
    end
  end
  
  describe 'with a while loop' do
    it 'should create a new block with a loop-back edge' do
      cfg = cfg_builder_for('def CFG_T1(x); while x > 10; x -= 1; end; 5; end').build
      first, b1, b2, last = %w(Enter B1 B2 Exit).map do |name|
        cfg.vertex_with_name(name)
      end
      cfg.should have_edge(first, b1)
      cfg.should have_edge(first, b2)
      cfg.should have_edge(b1, b1)
      cfg.should have_edge(b1, b2)
      cfg.should have_edge(b2, last)
    end
    
    it 'should return nil in a value context' do
      cfg = cfg_builder_for('def CFG_T1(x); while x > 10; x -= 1; end; end').build
      b2 = cfg.vertex_with_name('B2')
      assgn = b2.instructions.first
      assgn[0].should be :assign
      assgn[1].should be_a(Bindings::TemporaryBinding)
      assgn[2].should be nil
    end
    
    describe 'when nested' do
      it 'should produce an appropriate graph' do
        cfg = cfg_builder_for('def CFG_T1(x); while x > 10; y = x - 1; '+
                              'while y > 0; y -= 1; end; end; end').build
        first, b1, b2, b3, b4, b5, last = %w(Enter B1 B2 B3 B4 B5 Exit).map do |name|
          cfg.vertex_with_name(name)
        end
        cfg.should have_edge(first, b1)
        cfg.should have_edge(first, b2)
        
        cfg.should have_edge(b1, b3)
        cfg.should have_edge(b1, b4)
        cfg.should have_edge(b3, b3)
        cfg.should have_edge(b3, b4)
        
        cfg.should have_edge(b4, b2)
        cfg.should have_edge(b2, last)
      end
    end
  end
  
  describe 'with while as a modifier' do
    it 'should create a new block with a loop-back edge' do
      cfg = cfg_builder_for('def CFG_T1(x); x -= 1 while x > 10; 5; end').build
      first, b1, b2, last = %w(Enter B1 B2 Exit).map do |name|
        cfg.vertex_with_name(name)
      end
      cfg.should have_edge(first, b1)
      cfg.should have_edge(first, b2)
      cfg.should have_edge(b1, b1)
      cfg.should have_edge(b1, b2)
      cfg.should have_edge(b2, last)
    end
    
    
    it 'should return nil in a value context' do
      cfg = cfg_builder_for('def CFG_T1(x); x -= 1 while x > 10; end').build
      b2 = cfg.vertex_with_name('B2')
      assgn = b2.instructions.first
      assgn[0].should be :assign
      assgn[1].should be_a(Bindings::TemporaryBinding)
      assgn[2].should be nil
    end
  end
  
  describe 'with a until loop' do
    it 'should create a new block with a loop-back edge' do
      cfg = cfg_builder_for('def CFG_T1(x); until x > 10; x -= 1; end; 5; end').build
      first, b1, b2, last = %w(Enter B1 B2 Exit).map do |name|
        cfg.vertex_with_name(name)
      end
      cfg.should have_edge(first, b1)
      cfg.should have_edge(first, b2)
      cfg.should have_edge(b1, b1)
      cfg.should have_edge(b1, b2)
      cfg.should have_edge(b2, last)
    end
    
    it 'should return nil in a value context' do
      cfg = cfg_builder_for('def CFG_T1(x); until x > 10; x -= 1; end; end').build
      b2 = cfg.vertex_with_name('B2')
      assgn = b2.instructions.first
      assgn[0].should be :assign
      assgn[1].should be_a(Bindings::TemporaryBinding)
      assgn[2].should be nil
    end
  end
  
  describe 'with until as a modifier' do
    it 'should create a new block with a loop-back edge' do
      cfg = cfg_builder_for('def CFG_T1(x); x -= 1 until x > 10; 5; end').build
      first, b1, b2, last = %w(Enter B1 B2 Exit).map do |name|
        cfg.vertex_with_name(name)
      end
      cfg.should have_edge(first, b1)
      cfg.should have_edge(first, b2)
      cfg.should have_edge(b1, b1)
      cfg.should have_edge(b1, b2)
      cfg.should have_edge(b2, last)
    end
    
    
    it 'should return nil in a value context' do
      cfg = cfg_builder_for('def CFG_T1(x); x -= 1 until x > 10; end').build
      b2 = cfg.vertex_with_name('B2')
      assgn = b2.instructions.first
      assgn[0].should be :assign
      assgn[1].should be_a(Bindings::TemporaryBinding)
      assgn[2].should be nil
    end
  end
  
  describe 'with an if with no else/elsif' do
    describe 'when not used as a value' do
      it 'should branch both into and around the if body block' do
        cfg = cfg_builder_for('def CFG_T1(x); if x > 10; x -= 1; end; 5; end').build
        first, b1, b2, last = %w(Enter B1 B2 Exit).map do |name|
          cfg.vertex_with_name(name)
        end
        cfg.should have_edge(first, b1)
        cfg.should have_edge(first, b2)
        cfg.should have_edge(b2, b1)
        cfg.should have_edge(b1, last)
      end
    end
    
    describe 'when used as a value' do
      it 'in a used-value context, builds an extra block' do
        cfg = cfg_builder_for('def CFG_T1(x); if x > 10; x -= 1; end; end').build
        first, b1, b2, b3, last = %w(Enter B1 B2 B3 Exit).map do |name|
          cfg.vertex_with_name(name)
        end
        cfg.should have_edge(first, b2)
        cfg.should have_edge(first, b3)
        cfg.should have_edge(b2, b1)
        cfg.should have_edge(b3, b1)
        cfg.should have_edge(b1, last)
      end
      
      it 'returns nil when the condition fails' do
        cfg = cfg_builder_for('def CFG_T1(x); if x > 10; x -= 1; end; end').build
        first = cfg.vertex_with_name('Enter')
        # Sanity check
        first.instructions.last[0].should == :branch
        failure_block = cfg.vertex_with_name(first.instructions.last.last)
        assgn = failure_block.instructions.first
        assgn[0].should == :assign
        assgn[1].should be_a(Bindings::TemporaryBinding)
        assgn[2].should be nil
      end
      
      it 'returns the value of the last expression in the success body when the condition succeeds' do
        cfg = cfg_builder_for('def CFG_T1(x); if x > 10; x -= 1; 3.14; end; end').build
        first = cfg.vertex_with_name('Enter')
        # Sanity check
        first.instructions.last[0].should == :branch
        success_block = cfg.vertex_with_name(first.instructions.last[2])
        assgn = success_block.instructions[-3]
        assgn[0].should == :assign
        assgn[1].should be_a(Bindings::TemporaryBinding)
        assgn[2].should == 3.14
        
        return_assgn = success_block.instructions[-2]
        return_assgn[0].should == :assign
        return_assgn[1].should be_a(Bindings::TemporaryBinding)
        return_assgn[2].should be assgn[1]
      end
    end
  end
  
  describe 'with an if with an else' do
    it 'should branch both into and around the if body block' do
      cfg = cfg_builder_for('def CFG_T1(x); if x > 10; x -= 1; else; x = 20; end; 5; end').build
      first, b1, b2, b3, last = %w(Enter B1 B2 B3 Exit).map do |name|
        cfg.vertex_with_name(name)
      end
      cfg.should have_edge(first, b2)
      cfg.should have_edge(first, b3)
      cfg.should have_edge(b2, b1)
      cfg.should have_edge(b3, b1)
      cfg.should have_edge(b1, last)
    end
  end
  
  describe 'with an if with many elsifs (and no else)' do
    it 'should branch both into and around the if body block' do
      cfg = cfg_builder_for('def CFG_T1(x); if x > 10; x -= 1; elsif x == 10; x = 20;' +
                            ' elsif x == 9; 3.14; elsif x == 8; 5.55; end; end').build
      first, b1, b2, b3, b4, b5, b6, b7, b8, b9, last = %w(Enter B1 B2 B3 B4 B5 B6 B7 B8 B9 Exit).map do |name|
        cfg.vertex_with_name(name)
      end
      # first test
      cfg.should have_edge(first, b2)
      cfg.should have_edge(first, b3)
      
      # second test
      cfg.should have_edge(b3, b4)
      cfg.should have_edge(b3, b5)
      
      # third test
      cfg.should have_edge(b5, b6)
      cfg.should have_edge(b5, b7)
      
      # fourth test
      cfg.should have_edge(b7, b8)
      cfg.should have_edge(b7, b9)
      
      # all 5 possible results go to b1
      cfg.should have_edge(b2, b1)
      cfg.should have_edge(b4, b1)
      cfg.should have_edge(b6, b1)
      cfg.should have_edge(b8, b1)
      cfg.should have_edge(b9, b1)
      cfg.should have_edge(b1, last)
    end
  end
  
  describe 'return with no arguments' do
    it 'should add an edge to the Exit block' do
      cfg = cfg_builder_for('def CFG_T1(x); if x > 10; x -= 1; '+
                            'return; else; x = 5; end; end;').build
      first, b1, b2, b3, b4, last = %w(Enter B1 B2 B3 B4 Exit).map do |name|
        cfg.vertex_with_name(name)
      end
      
      cfg.should have_edge(first, b2)
      cfg.should have_edge(first, b3)
      cfg.should have_edge(b2, last)
      cfg.should_not have_edge(b2, b4)
      cfg.should have_edge(b3, b1)
      cfg.should have_edge(b4, b1)
      cfg.should have_edge(b1, last)
    end
  end
end