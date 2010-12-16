require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Scope::GlobalScope do
  it 'is a Scope object' do
    Scope::GlobalScope.should be_a(Scope)
  end
  
  it 'has no parent' do
    Scope::GlobalScope.parent.should be_nil
  end
  
  it 'has a self pointer that is an Object' do
    # self_ptr is a Symbol
    Scope::GlobalScope.self_ptr.class_used.path.should == 'Object'
  end
  
  it 'has Object in its constants table' do
    Scope::GlobalScope.constants['Object'].should_not be_nil
  end
end