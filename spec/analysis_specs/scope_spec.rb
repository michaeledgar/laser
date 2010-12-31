require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ScopeSpecHelpers
  def add_scope_instance_variables(klass)
    before do
      @base_scope = klass.new(Scope::GlobalScope, nil)
      WoolModule.new('ABD', @base_scope)  # ignore: unused return
      @nested_scope = klass.new(@base_scope, nil)
      WoolModule.new('OOP', @nested_scope)  # ignore: unused return
    end
  end
end

describe Scope::GlobalScope do
  it 'is a closed scope' do
    Scope::GlobalScope.should be_a(ClosedScope)
  end
  
  it 'has no parent' do
    Scope::GlobalScope.parent.should be_nil
  end
  
  it 'has a self pointer that is an Object' do
    # self_ptr is a Symbol
    Scope::GlobalScope.self_ptr.klass.path.should == 'Object'
    Scope::GlobalScope.self_ptr.name.should == 'main'
  end
  
  it 'has Object in its constants table' do
    Scope::GlobalScope.constants['Object'].should_not be_nil
  end
end

describe Scope do
  context '#initialize' do
    it 'refuses to instantiate a Scope' do
      lambda { Scope.new(mock, mock) }.should raise_error(NotImplementedError)
    end
  end
end

shared_examples_for Scope do
  extend AnalysisHelpers
  clean_registry

  before do
    @base_scope = described_class.new(Scope::GlobalScope, nil)
    WoolModule.new('ABD', @base_scope)  # ignore: unused return
    @nested_scope = described_class.new(@base_scope, nil)
    WoolModule.new('OOP', @nested_scope)  # ignore: unused return
  end

  describe '#lookup' do
    it 'looks up a constant if given a query starting with a capital letter' do
      Scope::GlobalScope.lookup('ABD').scope.should == @base_scope
      @base_scope.lookup('OOP').scope.should == @nested_scope
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
  
  describe '#lookup_path' do
    it 'looks up 2 scopes in a path' do
      Scope::GlobalScope.lookup_path('ABD::OOP').should == @nested_scope
    end
    
    it 'raises a ScopeLookupFailure on failure' do
      lambda {
        Scope::GlobalScope.lookup_path('ABD::ABC987') 
      }.should raise_error(Scope::ScopeLookupFailure)
      begin
        Scope::GlobalScope.lookup_path('ABD::ABC987')
      rescue Scope::ScopeLookupFailure => err
        err.scope.should == @base_scope
        err.query.should == 'ABC987'
      end
    end
  end
end

describe OpenScope do
  it_should_behave_like Scope
  extend ScopeSpecHelpers
  add_scope_instance_variables(OpenScope)
  
  describe '#lookup_local' do
    it 'should look in parent scopes when lookup fails' do
      expected = Object.new
      @base_scope.locals['x'] = expected
      @nested_scope.lookup_local('x').should be expected
    end
    
    it 'should raise if there is no parent' do
      scope = OpenScope.new(nil, nil)
      lambda { scope.lookup('foobarmonkey') }.should raise_error(Scope::ScopeLookupFailure)
    end
  end
end

describe ClosedScope do
  it_should_behave_like Scope
  extend ScopeSpecHelpers
  add_scope_instance_variables(ClosedScope)
  
  describe '#lookup_local' do
    it 'should not look in parent scopes when lookup fails' do
      value = Object.new
      @base_scope.locals['x'] = value
      lambda {
        @nested_scope.lookup_local('x')
      }.should raise_error(Scope::ScopeLookupFailure)
    end
  end
end