require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SexpAnalysis::Symbol do
  describe '#initialize' do
    it 'has a simple struct-like initializer' do
      proto, klass, scope, name, value = many_mocks(5)
      sym = SexpAnalysis::Symbol.new(proto, klass, scope, name, value)
      sym.protocol.should == proto
      sym.class_used.should == klass
      sym.scope.should == scope
      sym.name.should == name
      sym.value.should == value
    end
    
    it 'also supports a single, hash initializing argument' do
      proto, klass, scope, name, value = many_mocks(5)
      sym = SexpAnalysis::Symbol.new(
          :protocol => proto, :class_used => klass, :scope => scope,
          :name => name, :value => value)
      sym.protocol.should == proto
      sym.class_used.should == klass
      sym.scope.should == scope
      sym.name.should == name
      sym.value.should == value
    end
  end
  
  describe '#<=>' do
    it 'should compare based on name alone' do
      proto, klass, scope, value = many_mocks(4)
      sym1 = SexpAnalysis::Symbol.new(
          :protocol => proto, :class_used => klass, :scope => scope,
          :name => 'Hello', :value => value)
      sym2 = SexpAnalysis::Symbol.new(
          :protocol => proto, :class_used => klass, :scope => scope,
          :name => 'Helga', :value => value)
      sym1.should > sym2
    end
  end
end