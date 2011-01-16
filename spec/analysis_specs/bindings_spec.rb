require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SexpAnalysis::Bindings::GenericBinding do
  describe '#initialize' do
    it 'has a simple struct-like initializer' do
      name, value = many_mocks(2)
      sym = SexpAnalysis::Bindings::GenericBinding.new(name, value)
      sym.name.should == name
      sym.value.should == value
    end
  end
  
  describe '#<=>' do
    it 'should compare based on name alone' do
      value = mock
      sym1 = SexpAnalysis::Bindings::GenericBinding.new('hello', value)
      sym2 = SexpAnalysis::Bindings::GenericBinding.new('helga', value)
      sym1.should > sym2
    end
  end
end

describe SexpAnalysis::Bindings::ConstantBinding do
  describe '#bind!' do
    it 'should raise on a rebinding when not forcing' do
      sym = SexpAnalysis::Bindings::ConstantBinding.new('hi', 1)
      expect { sym.bind!(2) }.to raise_error(TypeError)
    end
    
    it 'should not raise on a rebinding when forcing' do
      sym = SexpAnalysis::Bindings::ConstantBinding.new('hi', 3)
      sym.bind!(4, true)
      sym.value.should == 4
    end
  end
end