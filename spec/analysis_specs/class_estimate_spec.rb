require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SexpAnalysis::ClassEstimate do
  describe '#initialize' do
    it 'takes an upper and lower bound' do
      estimate = ClassEstimate.new(ClassRegistry['Numeric'], ClassRegistry['Fixnum'])
      estimate.upper_bound.should == ClassRegistry['Numeric']
      estimate.lower_bound.should == ClassRegistry['Fixnum']
    end
  end
  
  describe '#exact?' do
    it 'should check if the lower bound equals the upper bound' do
      ClassEstimate.new(ClassRegistry['String'], ClassRegistry['String']).should be_exact
      ClassEstimate.new(ClassRegistry['Regexp'], ClassRegistry['Regexp']).should be_exact
    end
  end
  
  describe '#inexact?' do
    it 'should check if the lower bound does not equal the upper bound' do
      ClassEstimate.new(ClassRegistry['Object'], ClassRegistry['String']).should be_inexact
      ClassEstimate.new(ClassRegistry['Numeric'], ClassRegistry['Integer']).should be_inexact
    end
  end
  
  describe '#upper_bound=' do
    before do
      @estimate = ClassEstimate.new(ClassRegistry['Integer'])
    end

    it 'does nothing if the new upper bound is a superclass of the old upper bound' do
      @estimate.upper_bound = ClassRegistry['Numeric']
      @estimate.upper_bound.should == ClassRegistry['Integer']
    end

    it 'refines the estimate if the new upper bound is a subclass of the old upper bound' do
      @estimate.upper_bound = ClassRegistry['Fixnum']
      @estimate.upper_bound.should == ClassRegistry['Fixnum']
    end
    
    it 'raises if the new upper bound crosses the lower bound' do
      estimate = ClassEstimate.new(ClassRegistry['Numeric'], ClassRegistry['Integer'])
      expect { estimate.upper_bound = ClassRegistry['Fixnum'] }.to raise_error(Exception)
    end
    
    it 'raises if the new upper bound is unrelated to the old upper bound' do
      expect { @estimate.upper_bound = ClassRegistry['String'] }.to raise_error(Exception)
    end
  end
end