require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'
describe ParentAnnotation do
  it 'adds the #parent method to Sexp' do
    Sexp.instance_methods.should include(:parent)
  end
  
  it 'adds parents to each node with a toy example' do
    tree = Sexp.new([:abc, Sexp.new([:def, 1, 2]),
                    Sexp.new([:zzz, Sexp.new([:return]),  "hi", Sexp.new([:silly, 4])])])
    ParentAnnotation::Annotator.new.annotate!(tree)
    expectalot(:parent => { nil => [tree], tree => [tree[1], tree[2]],
                            tree[2] => [tree[2][1], tree[2][3]] } )
  end
  
  # This will actually verify that every node in the tree has a
  # proper parent set. It's a complex, but thorough test.
  it 'adds parents to each node with a real-world parse result' do
    tree = Sexp.new(Ripper.sexp('x = proc {|x, *rst, &blk| p x ** rst[0]; blk.call(rst[1..-1])}'))
    expectalot(:parent => { nil => [tree], tree => [tree.children.first] })
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
    ParentAnnotation::Annotator.new.annotate!(tree)
    expectalot(:ancestors => { [] => [tree], [tree] => [tree[1], tree[2]],
                            [tree, tree[2]] => [tree[2][1], tree[2][3]] } )
  end
  
  # This will actually verify that every node in the tree has a
  # proper parent set. It's a complex, but thorough test.
  it 'adds parents to each node with a real-world parse result' do
    tree = Sexp.new(Ripper.sexp('x = proc {|x, *rst, &blk| p x ** rst[0]; blk.call(rst[1..-1])}'))
    expectalot(:parent => { nil => [tree], tree => [tree.children.first] })
    tree.all_subtrees.each do |node|
      if node.parent
        node.ancestors.should include(node.parent)
        (node.ancestors & node.parent.ancestors).should == node.parent.ancestors
      end
    end
  end
end