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
end