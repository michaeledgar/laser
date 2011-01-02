require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SexpAnalysis::Symbol do
  describe '#initialize' do
    it 'has a simple struct-like initializer' do
      name, value = many_mocks(2)
      sym = SexpAnalysis::Symbol.new(name, value)
      sym.name.should == name
      sym.value.should == value
    end
  end
  
  describe '#<=>' do
    it 'should compare based on name alone' do
      value = mock
      sym1 = SexpAnalysis::Symbol.new('hello', value)
      sym2 = SexpAnalysis::Symbol.new('helga', value)
      sym1.should > sym2
    end
  end
end