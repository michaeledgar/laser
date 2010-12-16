require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'
describe ParentAnnotation do
  it 'adds the #parent method to Sexp' do
    Sexp.instance_methods.should include(:parent)
  end
  
  it 'adds parents to each node with a toy example' do
    tree = Sexp.new([:abc, Sexp.new([:def, 1, 2]),
                                   Sexp.new([:zzz, Sexp.new([:return]), 
                                                           "hi", Sexp.new([:silly, 4])])])
    ParentAnnotation::Annotator.new.annotate!(tree)
    tree.parent.should == nil
    tree[1].parent.should == tree
    tree[2].parent.should == tree
    tree[2][1].parent.should == tree[2]
    tree[2][3].parent.should == tree[2]
  end
  
  # This will actually verify that every node in the tree has a
  # proper parent set. It's a complex, but thorough test.
  it 'adds parents to each node with a real-world parse result' do
    tree = Sexp.new(Ripper.sexp('x = proc {|x, *rst, &blk| p x ** rst[0]; blk.call(rst[1..-1])}'))
    tree.parent.should == nil
    tree.children[0].parent.should == tree
    visited = Set.new
    to_visit = tree.children
    while to_visit.any?
      todo = to_visit.pop
      next unless Sexp === todo
      todo.parent.children.should include(todo) 
      visited << todo
      
      case todo[0]
      when Array
        to_visit.concat todo
      when Symbol
        to_visit.concat todo.children
      end
    end
  end
end