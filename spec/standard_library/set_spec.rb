require File.dirname(__FILE__) + '/spec_helper'

describe 'the Set module' do
  before(:all) do
    @tree = annotate_all('require "set"')
  end

  it 'should have no errors from the inclusion' do
    @tree.all_errors.should be_empty
  end

  it 'should load fine' do
    ClassRegistry['Set'].should_not be_nil
  end
  
  it 'should have a class method .[]' do
    method = ClassRegistry['Set'].singleton_class.instance_method(:[])
    method.should_not be_nil
    method.arity.should == Arity::ANY
    method.arguments.size.should == 1
  end
  
  %w(& + - << == ^ add add? classify clear collect! delete delete? delete_if difference divide
     each empty? flatten flatten! flatten_merge include? initialize_copy inspect intersection
     length map! member? merge proper_subset? proper_superset? reject! replace size
     subset? subtract superset? to_a union |).each do |method|
    it "should have an instance method named #{method}" do
      ClassRegistry['Set'].instance_method(method).should_not be_nil
    end
  end
end
