require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SexpAnalysis::GenericBinding do
  describe '#initialize' do
    it 'has a simple struct-like initializer' do
      name, value = many_mocks(2)
      sym = SexpAnalysis::GenericBinding.new(name, value)
      sym.name.should == name
      sym.value.should == value
    end
  end
  
  describe '#<=>' do
    it 'should compare based on name alone' do
      value = mock
      sym1 = SexpAnalysis::GenericBinding.new('hello', value)
      sym2 = SexpAnalysis::GenericBinding.new('helga', value)
      sym1.should > sym2
    end
  end
end