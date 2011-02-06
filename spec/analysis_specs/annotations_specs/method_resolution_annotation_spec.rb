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
      tree.all_errors.size.should be 1
      tree.all_errors[0].should be_a(NotInMethodError)
    end
    
    it "should bind to the first superclass implementation of the method" do
      input = "class A992; def silly(x); end; end; class B992 < A992; end\n" +
              'class C992 < B992; def silly(x); super(x); end; end'
      tree = annotate_all(input)
      sexp = tree.deep_find { |node| node.type == :super }
      expected_method = ClassRegistry['A992'].instance_methods['silly']
      sexp.method_estimate.should == Set.new([expected_method])
    end
    
    it 'gives an error if no superclass implements the given method' do
      input = "class A994; end; class B994 < A994; end\n" +
              'class C994 < B994; def silly(x); super(x); end; end'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should be 1
      tree.all_errors[0].should be_a(NoSuchMethodError)
    end
  end
  
  describe 'using implicit super' do
    it 'should give an error if used outside of a method' do
      tree = annotate_all('class A994; super; end')
      tree.all_errors.should_not be_empty
      tree.all_errors[0].should be_a(NotInMethodError)
    end
    
    it "should bind to the first superclass implementation of the method" do
      input = "class A993; def silly(x); end; end; class B993 < A993; end\n" +
              'class C993 < B993; def silly(x); super; end; end'
      tree = annotate_all(input)
      sexp = tree.deep_find { |node| node.type == :zsuper }
      expected_method = ClassRegistry['A993'].instance_methods['silly']
      sexp.method_estimate.should == Set.new([expected_method])
    end
    
    it 'gives an error if no superclass implements the given method' do
      input = "class A995; end; class B995 < A995; end\n" +
              'class C995 < B995; def silly(x); super; end; end'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should be 1
      tree.all_errors[0].should be_a(NoSuchMethodError)
    end
  end
end