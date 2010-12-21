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

describe Scope do
  before do
    @new_scope = Scope.new(Scope::GlobalScope, nil)
    @abd = WoolModule.new('ABD', @new_scope)
    @third_scope = Scope.new(@new_scope, nil)
    @oop = WoolModule.new('OOP', @third_scope)
  end

  describe '#lookup' do
    it 'looks up a constant if given a query starting with a capital letter' do
      Scope::GlobalScope.lookup('ABD').scope.should == @new_scope
      @new_scope.lookup('OOP').scope.should == @third_scope
    end

    it 'raises a ScopeLookupFailure on failure' do
      lambda { Scope::GlobalScope.lookup('ABC987') }.should raise_error(Scope::ScopeLookupFailure)
      begin
        Scope::GlobalScope.lookup('ABC987')
      rescue Scope::ScopeLookupFailure => err
        err.scope.should == Scope::GlobalScope
        err.query.should == 'ABC987'
      end
    end
  end
  
  describe '#lookup_constant_with_path' do
    it 'looks up 2 scopes in a path' do
      Scope::GlobalScope.lookup_constant_with_path('ABD::OOP').should == @oop
    end
    
    it 'raises a ScopeLookupFailure on failure' do
      lambda {
        Scope::GlobalScope.lookup_constant_with_path('ABD::ABC987') 
      }.should raise_error(Scope::ScopeLookupFailure)
      begin
        Scope::GlobalScope.lookup_constant_with_path('ABD::ABC987')
      rescue Scope::ScopeLookupFailure => err
        err.scope.should == @new_scope
        err.query.should == 'ABC987'
      end
    end
  end
end