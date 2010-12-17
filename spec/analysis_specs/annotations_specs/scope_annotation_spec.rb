require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'
describe ScopeAnnotation do
  it 'adds the #scope method to Sexp' do
    Sexp.instance_methods.should include(:scope)
  end
  
  it 'adds scopes to each node with a flat example with no new scopes' do
    tree = Sexp.new(Ripper.sexp('a = nil; b = a; if b; a; end'))
    ScopeAnnotation::Annotator.new.annotate!(tree)
    all_sexps_in_subtree(tree).each do |node|
      node.scope.should == Scope::GlobalScope
    end
  end
  
  it 'creates a new scope when a simple module declaration is encountered' do
    sexp = [:program,
           [[:assign, [:var_field, [:@ident, "a", [1, 0]]], [:var_ref, [:@kw, "nil", [1, 4]]]],
            [:module, [:const_ref, [:@const, "A", [1, 16]]],
              [:bodystmt, [[:void_stmt], [:assign, [:var_field, [:@ident, "a", [1, 19]]],
              [:@int, "10", [1, 23]]]], nil, nil, nil]]]]
    tree = Sexp.new(Ripper.sexp('a = nil; module A; a = 10; end'))
    ScopeAnnotation::Annotator.new.annotate!(tree)
    tree.should == sexp
    tree.scope.should == Scope::GlobalScope
    list = tree[1]
    list[0].scope.should == Scope::GlobalScope
    list[0][1].scope.should == Scope::GlobalScope
    list[0][2].scope.should == Scope::GlobalScope
    list[1][2].scope.should_not == Scope::GlobalScope
    list[1][2].scope.self_ptr.should == Scope::GlobalScope.constants['A']
    mod = list[1][2].scope.self_ptr
    mod.name.should == 'A'
    all_sexps_in_subtree(list[1][2]).each do |node|
      node.scope.should == list[1][2].scope
    end
  end
end