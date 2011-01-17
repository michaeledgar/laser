require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe ScopeAnnotation do
  extend AnalysisHelpers
  clean_registry
  
  it 'adds the #class_estimate method to Sexp' do
    Sexp.instance_methods.should include(:class_estimate)
  end
  
  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # [:program,
  # [[:assign,
  #    [:var_field, [:@ident, "a", [1, 0]]], [:@int, "5", [1, 4]]]]]
  it 'discovers the class for integer literals' do
    tree = Sexp.new(Ripper.sexp('a = 5'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['Fixnum']
  end
  
  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # [:program,
  # [[:assign,
  #   [:var_field, [:@ident, "a", [1, 0]]],
  #   [:string_literal,
  #    [:string_content,
  #     [:@tstring_content, "abc = ", [1, 5]],
  #     [:string_embexpr,
  #      [[:binary,
  #        [:var_ref, [:@ident, "run_method", [1, 13]]],
  #        :-,
  #        [:@int, "5", [1, 26]]]]]]]]]]
  it 'discovers the class for nontrivial string literals' do
    tree = Sexp.new(Ripper.sexp('a = "abc = #{run_method - 5}"'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['String']
  end
end