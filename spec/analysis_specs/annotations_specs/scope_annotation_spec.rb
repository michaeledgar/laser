require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'
describe ParentAnnotation do
  it 'adds the #parent method to Sexp' do
    Sexp.instance_methods.should include(:scope)
  end
  
  it 'adds parents to each node with a toy example' do
    tree = Sexp.new(Ripper.sexp('a = nil; b = a; if b; a; end'))
    ScopeAnnotation::Annotator.new.annotate!(tree)
  end
end