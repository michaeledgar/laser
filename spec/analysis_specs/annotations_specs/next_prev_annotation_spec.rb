require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'
describe NextPrevAnnotation do
  it_should_behave_like 'an annotator'
  
  it 'adds the #next and #prev methods to Sexp' do
    Sexp.instance_methods.should include(:next)
    Sexp.instance_methods.should include(:prev)
  end
  
  it 'adds next and prevs to each node with a toy example' do
    tree = Sexp.new([:abc, Sexp.new([:def, 1, 2]),
                    Sexp.new([:zzz, Sexp.new([:return]), "hi", Sexp.new([:silly, 4])])])
    NextPrevAnnotation.new.annotate!(tree)
    expectalot(prev: { nil => [tree[1], tree[2][1]], tree[1] => [tree[2]], tree[2][2] => [tree[2][3]] },
               next: { nil => [tree[2], tree[2][3]], tree[2] => [tree[1]], tree[2][2] => [tree[2][1]] })
  end
  
  # This will actually verify that every node in the tree has a
  # proper parent set. It's a complex, but thorough test.
  it 'adds next and prevs to each node with a real-world parse result' do
    tree = Sexp.new(Ripper.sexp('x = proc {|x, *rst, &blk| p x ** rst[0]; blk.call(rst[1..-1])}'))
    expectalot(next: { nil => [tree] }, prev: { nil => [tree] })
    visited = Set.new
    tree.all_subtrees.each do |node|
      node.prev.next.should == node if node.is_sexp?(node.prev)
      node.next.prev.should == node if node.is_sexp?(node.next)
    end
  end
end