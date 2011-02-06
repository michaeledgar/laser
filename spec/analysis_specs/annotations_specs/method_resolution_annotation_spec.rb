require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe LiteralTypeAnnotation do
  extend AnalysisHelpers
  clean_registry
  
  it_should_behave_like 'an annotator'
  
  it 'adds the #class_estimate method to Sexp' do
    Sexp.instance_methods.should include(:method_estimate)
  end
  
  describe 'using explicit super' do
    it 'should give an error if used outside of a method' do
      tree = annotate_all('class A991; super(); end')
      tree.all_errors.should_not be_empty
      tree.all_errors[0].should be_a(NotInMethodError)
    end
  end
end