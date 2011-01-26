require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'the automatically analyzed Ruby Standard Library' do
  shared_examples_for 'a module' do
    it 'should be a module' do
      @module.class.should == LaserModule
    end
  end
  
  shared_examples_for 'a class' do
    it 'should be a class' do
      @class.class.should == LaserClass
    end
  end

  describe 'Kernel' do
    before do
      @module = ClassRegistry['Kernel']
    end
    
    it_should_behave_like 'a module'
  end
  describe 'Object' do
    before do
      @class = ClassRegistry['Object']
    end

    it 'should have no superclass' do
      @class.superclass.should == nil
    end
    
    it 'should include the Kernel module' do
      @class.included_modules.should include(ClassRegistry['Kernel'])
    end
    
    it_should_behave_like 'a class'
  end

  describe 'NilClass' do
    before do
      @class = ClassRegistry['NilClass']
    end
  
    it 'should be a subclass of Object' do
      @class.superclass.should == ClassRegistry['Object']
    end
    
    it_should_behave_like 'a class'
  end
  describe 'TrueClass' do
    before do
      @class = ClassRegistry['TrueClass']
    end
  
    it 'should be a subclass of Object' do
      @class.superclass.should == ClassRegistry['Object']
    end
    
    it_should_behave_like 'a class'
  end
  describe 'FalseClass' do
    before do
      @class = ClassRegistry['FalseClass']
    end
  
    it 'should be a subclass of Object' do
      @class.superclass.should == ClassRegistry['Object']
    end
    
    it_should_behave_like 'a class'
  end

  describe 'Hash' do
    before do
      @class = ClassRegistry['Hash']
    end
  
    it 'should be a subclass of Object' do
      @class.superclass.should == ClassRegistry['Object']
    end
    
    it_should_behave_like 'a class'
  end

  describe 'Array' do
    before do
      @class = ClassRegistry['Array']
    end
  
    it 'should be a subclass of Object' do
      @class.superclass.should == ClassRegistry['Object']
    end
    
    it_should_behave_like 'a class'
  end

  describe 'Range' do
    before do
      @class = ClassRegistry['Range']
    end
  
    it 'should be a subclass of Object' do
      @class.superclass.should == ClassRegistry['Object']
    end
    
    it_should_behave_like 'a class'
  end

  describe 'Proc' do
    before do
      @class = ClassRegistry['Proc']
    end
  
    it 'should be a subclass of Object' do
      @class.superclass.should == ClassRegistry['Object']
    end
    
    it_should_behave_like 'a class'
  end

  describe 'String' do
    before do
      @class = ClassRegistry['String']
    end
  
    it 'should be a subclass of Object' do
      @class.superclass.should == ClassRegistry['Object']
    end
    
    it_should_behave_like 'a class'
  end

  describe 'Symbol' do
    before do
      @class = ClassRegistry['Symbol']
    end
  
    it 'should be a subclass of Object' do
      @class.superclass.should == ClassRegistry['Object']
    end
    
    it_should_behave_like 'a class'
  end

  describe 'Regexp' do
    before do
      @class = ClassRegistry['Regexp']
    end
  
    it 'should be a subclass of Object' do
      @class.superclass.should == ClassRegistry['Object']
    end
    
    it_should_behave_like 'a class'
  end
  
  describe 'Encoding' do
    before do
      @class = ClassRegistry['Encoding']
    end
  
    it 'should be a subclass of Object' do
      @class.superclass.should == ClassRegistry['Object']
    end
    
    it_should_behave_like 'a class'
  end

  describe 'Numeric' do
    before do
      @class = ClassRegistry['Numeric']
    end
  
    it 'should be a subclass of Object' do
      @class.superclass.should == ClassRegistry['Object']
    end
    
    it_should_behave_like 'a class'
  end
  
  describe 'Integer' do
    before do
      @class = ClassRegistry['Integer']
    end

    it 'should be a subclass of Numeric' do
      @class.superclass.should == ClassRegistry['Numeric']
    end
    
    it_should_behave_like 'a class'
  end

  describe 'Fixnum' do
    before do
      @class = ClassRegistry['Fixnum']
    end

    it 'should be a subclass of Integer' do
      @class.superclass.should == ClassRegistry['Integer']
    end
    
    it_should_behave_like 'a class'
  end

  describe 'Bignum' do
    before do
      @class = ClassRegistry['Bignum']
    end

    it 'should be a subclass of Integer' do
      @class.superclass.should == ClassRegistry['Integer']
    end
    
    it_should_behave_like 'a class'
  end

  describe 'Float' do
    before do
      @class = ClassRegistry['Float']
    end

    it 'should be a subclass of Numeric' do
      @class.superclass.should == ClassRegistry['Numeric']
    end
    
    it_should_behave_like 'a class'
  end
end