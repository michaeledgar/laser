require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'
describe ExpandedIdentifierAnnotation do
  it_should_behave_like 'an annotator'
  
  it 'adds the #expanded_identifier method to Sexp' do
    Sexp.instance_methods.should include(:expanded_identifier)
  end
  
  ['abc', '@abc', 'ABC', '@@abc', '$abc'].each do |id|
    tree = Sexp.new(Ripper.sexp(id))
    it "discovers expanded identifiers for simple identifiers of type #{tree[1][0][0]}" do
      ExpandedIdentifierAnnotation.new.annotate_with_text(tree, id)
      tree[1][0].expanded_identifier.should == id
    end
  end
end