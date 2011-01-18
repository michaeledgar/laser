require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SexpAnalysis::ClassEstimate do
  describe '#initialize' do
    it 'takes an upper and lower bound' do
      estimate = ClassEstimate.new(ClassRegistry['Numeric'], ClassRegistry['Fixnum'])
      estimate.upper_bound.should == ClassRegistry['Numeric']
      estimate.lower_bound.should == ClassRegistry['Fixnum']
    end
  end
  
  describe 'an exact class estimate' do
    before do
      @estimate = ClassEstimate.new(ClassRegistry['String'], ClassRegistry['String'])
    end
    describe '#exact_class' do
      it 'should return the exact class' do
        @estimate.exact_class.should == ClassRegistry['String']
      end
    end
    describe '#exact?' do
      it 'should be true' do
        @estimate.should be_exact
      end
    end
  end
 
  describe 'an inexact class estimate' do
    before do
      @estimate = ClassEstimate.new(ClassRegistry['Numeric'], ClassRegistry['Fixnum'])
    end
    describe '#exact_class' do
      it 'should raise an error' do
        expect { @estimate.exact_class }.to raise_error(Exception)
      end
    end
    describe '#inexact?' do
      it 'should be true' do
        @estimate.should be_inexact
      end
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
      expect { @estimate.upper_bound = ClassRegistry['Float'] }.to raise_error(Exception)
    end
  end
  
  describe '#lower_bound=' do
    before do
      @estimate = ClassEstimate.new(ClassRegistry['Object'], ClassRegistry['Integer'])
    end

    it 'does nothing if the new lower bound is a subclass of the old lower bound' do
      @estimate.lower_bound = ClassRegistry['Fixnum']
      @estimate.lower_bound.should == ClassRegistry['Integer']
    end

    it 'refines the estimate if the new lower bound is a superclass of the old lower bound' do
      @estimate.lower_bound = ClassRegistry['Numeric']
      @estimate.lower_bound.should == ClassRegistry['Numeric']
    end
    
    it 'raises if the new lower bound crosses the upper bound' do
      estimate = ClassEstimate.new(ClassRegistry['Integer'], ClassRegistry['Fixnum'])
      expect { estimate.lower_bound = ClassRegistry['Numeric'] }.to raise_error(Exception)
    end
    
    it 'raises if the new lower bound is unrelated to the old lower bound' do
      expect { @estimate.lower_bound = ClassRegistry['Float'] }.to raise_error(Exception)
    end
  end
end

describe SexpAnalysis::ExactClassEstimate do
  describe '#initialize' do
    it 'takes a single class to specify exactly' do
      estimate = ExactClassEstimate.new(ClassRegistry['Numeric'])
      estimate.upper_bound.should == ClassRegistry['Numeric']
      estimate.lower_bound.should == ClassRegistry['Numeric']
    end
  end
  
  describe 'as an exact class estimate' do
    before do
      @estimate = ExactClassEstimate.new(ClassRegistry['String'])
    end
    describe '#exact_class' do
      it 'should return the exact class' do
        @estimate.exact_class.should == ClassRegistry['String']
      end
    end
    describe '#exact?' do
      it 'should be true' do
        @estimate.should be_exact
      end
    end
  end
end