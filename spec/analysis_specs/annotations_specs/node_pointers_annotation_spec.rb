require_relative 'spec_helper'
require 'set'
describe NodePointersAnnotation do
  it_should_behave_like 'an annotator'
  
  it 'adds the #parent method to Sexp' do
    Sexp.instance_methods.should include(:parent)
  end
  
  it 'adds parents to each node with a toy example' do
    tree = Sexp.new([:abc, Sexp.new([:def, 1, 2]),
                    Sexp.new([:zzz, Sexp.new([:return]),  "hi", Sexp.new([:silly, 4])])])
    NodePointersAnnotation.new.annotate!(tree)
    expectalot(parent: { nil => [tree], tree => [tree[1], tree[2]],
                            tree[2] => [tree[2][1], tree[2][3]] } )
  end
  
  # This will actually verify that every node in the tree has a
  # proper parent set. It's a complex, but thorough test.
  it 'adds parents to each node with a real-world parse result' do
    tree = Sexp.new(Ripper.sexp('x = proc {|x, *rst, &blk| p x ** rst[0]; blk.call(rst[1..-1])}'))
    NodePointersAnnotation.new.annotate!(tree)
    expectalot(parent: { nil => [tree], tree => [tree.children.first] })
    tree.all_subtrees.each do |node|
      node.parent.children.should include(node)
    end
  end

  it 'adds the #ancestors method to Sexp' do
    Sexp.instance_methods.should include(:ancestors)
  end
  
  it 'adds ancestors to each node with a toy example' do
    tree = Sexp.new([:abc, Sexp.new([:def, 1, 2]),
                    Sexp.new([:zzz, Sexp.new([:return]), 'hi', Sexp.new([:silly, 4])])])
    NodePointersAnnotation.new.annotate!(tree)
    expectalot(ancestors: { [] => [tree], [tree] => [tree[1], tree[2]],
                            [tree, tree[2]] => [tree[2][1], tree[2][3]] } )
  end
  
  it 'adds the #root method to Sexp' do
    Sexp.instance_methods.should include(:root)
  end
  
  it 'can compute the root from any node in the tree' do
    tree = Sexp.new(Ripper.sexp('x = proc {|x, *rst, &blk| p x ** rst[0]; blk.call(rst[1..-1])}'))
    NodePointersAnnotation.new.annotate!(tree)
    tree.dfs { |node| node.root.should be tree }
  end
  
  # This will actually verify that every node in the tree has a
  # proper parent set. It's a complex, but thorough test.
  it 'adds parents to each node with a real-world parse result' do
    tree = Sexp.new(Ripper.sexp('x = proc {|x, *rst, &blk| p x ** rst[0]; blk.call(rst[1..-1])}'))
    NodePointersAnnotation.new.annotate!(tree)
    expectalot(parent: { nil => [tree], tree => [tree.children.first] })
    tree.all_subtrees.each do |node|
      if node.parent
        node.ancestors.should include(node.parent)
        (node.ancestors & node.parent.ancestors).should == node.parent.ancestors
      end
    end
  end
  
  it 'adds the #next and #prev methods to Sexp' do
    Sexp.instance_methods.should include(:next)
    Sexp.instance_methods.should include(:prev)
  end
  
  it 'adds next and prevs to each node with a toy example' do
    tree = Sexp.new([:abc, Sexp.new([:def, 1, 2]),
                    Sexp.new([:zzz, Sexp.new([:return]), "hi", Sexp.new([:silly, 4])])])
    NodePointersAnnotation.new.annotate!(tree)
    expectalot(prev: { nil => [tree[1], tree[2][1]], tree[1] => [tree[2]], tree[2][2] => [tree[2][3]] },
               next: { nil => [tree[2], tree[2][3]], tree[2] => [tree[1]], tree[2][2] => [tree[2][1]] })
  end
  
  # This will actually verify that every node in the tree has a
  # proper parent set. It's a complex, but thorough test.
  it 'adds next and prevs to each node with a real-world parse result' do
    tree = Sexp.new(Ripper.sexp('x = proc {|x, *rst, &blk| p x ** rst[0]; blk.call(rst[1..-1])}'))
    NodePointersAnnotation.new.annotate!(tree)
    expectalot(next: { nil => [tree] }, prev: { nil => [tree] })
    visited = Set.new
    tree.all_subtrees.each do |node|
      node.prev.next.should == node if node.is_sexp?(node.prev)
      node.next.prev.should == node if node.is_sexp?(node.next)
    end
  end
end
