require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module ScopeSpecHelpers
  def add_scope_instance_variables(klass)
    before do
      @base_scope = klass.new(Scope::GlobalScope, nil)
      LaserModule.new('ABD', @base_scope)  # ignore: unused return
      @nested_scope = klass.new(@base_scope, nil)
      LaserModule.new('OOP', @nested_scope)  # ignore: unused return
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
    # self_ptr is a Bindings::GenericBinding
    Scope::GlobalScope.self_ptr.klass.path.should == 'Object'
    Scope::GlobalScope.self_ptr.name.should == 'main'
  end
  
  it 'has Object in its constants table' do
    Scope::GlobalScope.constants['Object'].should_not be_nil
  end
end

describe Scope do
  describe '#initialize' do
    it 'refuses to instantiate a Scope' do
      expect { Scope.new(mock, mock) }.to raise_error(NotImplementedError)
    end
  end
end

shared_examples_for Scope do
  extend AnalysisHelpers
  clean_registry

  before do
    @base_scope = described_class.new(Scope::GlobalScope, nil)
    LaserModule.new('ABD', @base_scope)  # ignore: unused return
    @nested_scope = described_class.new(@base_scope, nil)
    LaserModule.new('OOP', @nested_scope)  # ignore: unused return
  end

  describe '#lookup' do
    it 'looks up a constant if given a query starting with a capital letter' do
      Scope::GlobalScope.lookup('ABD').scope.should == @base_scope
      @base_scope.lookup('OOP').scope.should == @nested_scope
    end

    it 'raises a ScopeLookupFailure on failure' do
      expect { Scope::GlobalScope.lookup('ABC987') }.to raise_error(Scope::ScopeLookupFailure)
      begin
        Scope::GlobalScope.lookup('ABC987')
      rescue Scope::ScopeLookupFailure => err
        err.scope.should == Scope::GlobalScope
        err.query.should == 'ABC987'
      end
    end
  end
  
  describe '#dup' do
    before do
      @a, @b, @c = many_mocks(3)
      @nested_scope.locals['a'] = @a
      @nested_scope.locals['b'] = @b
      @nested_scope.locals['c'] = @c
      @duplicate = @nested_scope.dup
    end
    it 'can duplicate itself, shallowly, retaining references to old bindings' do
      @duplicate.proper_variable_lookup('ABD::OOP').should be @nested_scope.proper_variable_lookup('ABD::OOP')
      @duplicate.lookup('a').should be @a
      @duplicate.lookup('b').should be @b
      @duplicate.lookup('c').should be @c
    end
    
    it 'retains the same reference to parent scopes' do
      @duplicate.parent.should be @nested_scope.parent
    end
    
    it 'retains the same reference to the self object' do
      @duplicate.self_ptr.should be @nested_scope.self_ptr
    end
    
    it "ensures changes to a duplicate's locals do not affect the original" do
      new_a = mock
      @duplicate.locals['a'] = new_a
      @nested_scope.lookup('a').should be @a
      @duplicate.lookup('a').should be new_a
    end
    
    it "ensures changes to a duplicate's constants do not affect the original" do
      new_a = mock
      @duplicate.constants['ABC999'] = new_a
      expect {
        @nested_scope.proper_variable_lookup('ABC999')
      }.to raise_error(Scope::ScopeLookupFailure)
      begin
        @nested_scope.proper_variable_lookup('ABC999')
      rescue Scope::ScopeLookupFailure => err
        err.scope.should == @nested_scope
        err.query.should == 'ABC999'
      end
      @duplicate.lookup('ABC999').should be new_a
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
      expect { scope.lookup('foobarmonkey') }.to raise_error(Scope::ScopeLookupFailure)
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
      expect {
        @nested_scope.lookup_local('x')
      }.to raise_error(Scope::ScopeLookupFailure)
    end
  end
end