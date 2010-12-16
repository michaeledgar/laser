require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'
describe NextPrevAnnotation do
  it 'adds the #next and #prev methods to Sexp' do
    Sexp.instance_methods.should include(:next)
    Sexp.instance_methods.should include(:prev)
  end
  
  it 'adds next and prevs to each node with a toy example' do
    tree = Sexp.new([:abc, Sexp.new([:def, 1, 2]),
                                   Sexp.new([:zzz, Sexp.new([:return]), 
                                                           "hi", Sexp.new([:silly, 4])])])
    NextPrevAnnotation::Annotator.new.annotate!(tree)
    tree[1].prev.should == nil
    tree[1].next.should == tree[2]
    tree[2].prev.should == tree[1]
    tree[2].next.should == nil
    tree[2][1].prev.should == nil
    tree[2][1].next.should == tree[2][2]
    tree[2][3].prev.should == tree[2][2]
    tree[2][3].next.should == nil
  end
  
  # This will actually verify that every node in the tree has a
  # proper parent set. It's a complex, but thorough test.
  it 'adds next and prevs to each node with a real-world parse result' do
    tree = Sexp.new(Ripper.sexp('x = proc {|x, *rst, &blk| p x ** rst[0]; blk.call(rst[1..-1])}'))
    tree.next.should == nil
    tree.prev.should == nil
    visited = Set.new
    to_visit = tree.children
    while to_visit.any?
      todo = to_visit.pop
      next unless is_sexp?(todo)
      
      todo.prev.next.should == todo if is_sexp?(todo.prev)
      todo.next.prev.should == todo if is_sexp?(todo.next)

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