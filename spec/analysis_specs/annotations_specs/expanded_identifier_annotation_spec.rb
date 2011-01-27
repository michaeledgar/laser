require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'
describe ExpandedIdentifierAnnotation do
  it_should_behave_like 'an annotator'
  
  it 'adds the #expanded_identifier method to Sexp' do
    Sexp.instance_methods.should include(:expanded_identifier)
  end
  
  ['abc', '@abc', 'ABC', '@@abc', '$abc'].each do |id|
    tree = Sexp.new(Ripper.sexp(id))
    actual_ident = tree[1][0][1]
    it "discovers expanded identifiers for simple identifiers of type #{actual_ident[0]}" do
      ExpandedIdentifierAnnotation.new.annotate_with_text(tree, id)
      actual_ident.expanded_identifier.should == id
    end
  end
  
  # [:program,
  #  [[:assign,
  #    [:var_field, [:@ident, "abc", [1, 0]]],
  #    [:var_ref, [:@const, "ABC", [1, 6]]]]]]
  it 'handles var_ref and var_field nodes' do
    input = 'abc = ABC'
    tree = Sexp.new(Ripper.sexp(input))
    ExpandedIdentifierAnnotation.new.annotate_with_text(tree, input)
    assign = tree[1][0]
    assign[1].expanded_identifier.should == 'abc'
    assign[2].expanded_identifier.should == 'ABC'
  end
  
  # [:program,
  # [[:assign,
  #   [:top_const_field, [:@const, "ABC", [1, 2]]],
  #   [:top_const_ref, [:@const, "DEF", [1, 10]]]]]]
  it 'handles top_const_ref and top_const_field nodes' do
    input = '::ABC = ::DEF'
    tree = Sexp.new(Ripper.sexp(input))
    ExpandedIdentifierAnnotation.new.annotate_with_text(tree, input)
    assign = tree[1][0]
    assign[1].expanded_identifier.should == 'ABC'
    assign[2].expanded_identifier.should == 'DEF'
  end
  
  # [:program,
  #  [[:class,
  #    [:const_ref, [:@const, "ABC", [1, 6]]],
  #    nil,
  #    [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]
  it 'handles const_ref nodes (found in module/class declarations)' do
    input = 'class ABC; end'
    tree = Sexp.new(Ripper.sexp(input))
    ExpandedIdentifierAnnotation.new.annotate_with_text(tree, input)
    klass = tree[1][0]
    klass[1].expanded_identifier.should == 'ABC'
  end
  
  # [:program,
  # [[:assign,
  #   [:top_const_field, [:@const, "ABC", [1, 2]]],
  #   [:top_const_ref, [:@const, "DEF", [1, 10]]]]]]
  it 'handles top_const_ref and top_const_field nodes' do
    input = '::ABC::DEF = ::DEF::XYZ'
    tree = Sexp.new(Ripper.sexp(input))
    ExpandedIdentifierAnnotation.new.annotate_with_text(tree, input)
    assign = tree[1][0]
    assign[1].expanded_identifier.should == 'ABC::DEF'
    assign[2].expanded_identifier.should == 'DEF::XYZ'
  end
end