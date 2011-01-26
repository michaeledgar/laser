require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'the automatically analyzed Ruby Standard Library' do
  describe 'Object' do
    before do
      @object_class = ClassRegistry['Object']
    end

    it 'should have no superclass' do
      @object_class.superclass.should == nil
    end
  end

  describe 'NilClass' do
    before do
      @object_class = ClassRegistry['NilClass']
    end
  
    it 'should be a subclass of Object' do
      @object_class.superclass.should == ClassRegistry['Object']
    end
  end
  describe 'TrueClass' do
    before do
      @object_class = ClassRegistry['TrueClass']
    end
  
    it 'should be a subclass of Object' do
      @object_class.superclass.should == ClassRegistry['Object']
    end
  end
  describe 'FalseClass' do
    before do
      @object_class = ClassRegistry['FalseClass']
    end
  
    it 'should be a subclass of Object' do
      @object_class.superclass.should == ClassRegistry['Object']
    end
  end

  describe 'Hash' do
    before do
      @object_class = ClassRegistry['Hash']
    end
  
    it 'should be a subclass of Object' do
      @object_class.superclass.should == ClassRegistry['Object']
    end
  end

  describe 'Array' do
    before do
      @object_class = ClassRegistry['Array']
    end
  
    it 'should be a subclass of Object' do
      @object_class.superclass.should == ClassRegistry['Object']
    end
  end

  describe 'Range' do
    before do
      @object_class = ClassRegistry['Range']
    end
  
    it 'should be a subclass of Object' do
      @object_class.superclass.should == ClassRegistry['Object']
    end
  end

  describe 'Proc' do
    before do
      @object_class = ClassRegistry['Proc']
    end
  
    it 'should be a subclass of Object' do
      @object_class.superclass.should == ClassRegistry['Object']
    end
  end

  describe 'String' do
    before do
      @object_class = ClassRegistry['String']
    end
  
    it 'should be a subclass of Object' do
      @object_class.superclass.should == ClassRegistry['Object']
    end
  end

  describe 'Symbol' do
    before do
      @object_class = ClassRegistry['Symbol']
    end
  
    it 'should be a subclass of Object' do
      @object_class.superclass.should == ClassRegistry['Object']
    end
  end

  describe 'Regexp' do
    before do
      @object_class = ClassRegistry['Regexp']
    end
  
    it 'should be a subclass of Object' do
      @object_class.superclass.should == ClassRegistry['Object']
    end
  end
  
  describe 'Encoding' do
    before do
      @object_class = ClassRegistry['Encoding']
    end
  
    it 'should be a subclass of Object' do
      @object_class.superclass.should == ClassRegistry['Object']
    end
  end

  describe 'Numeric' do
    before do
      @object_class = ClassRegistry['Numeric']
    end
  
    it 'should be a subclass of Object' do
      @object_class.superclass.should == ClassRegistry['Object']
    end
  end
  
  describe 'Integer' do
    before do
      @object_class = ClassRegistry['Integer']
    end

    it 'should be a subclass of Numeric' do
      @object_class.superclass.should == ClassRegistry['Numeric']
    end
  end

  describe 'Fixnum' do
    before do
      @object_class = ClassRegistry['Fixnum']
    end

    it 'should be a subclass of Integer' do
      @object_class.superclass.should == ClassRegistry['Integer']
    end
  end

  describe 'Bignum' do
    before do
      @object_class = ClassRegistry['Bignum']
    end

    it 'should be a subclass of Integer' do
      @object_class.superclass.should == ClassRegistry['Integer']
    end
  end

  describe 'Float' do
    before do
      @object_class = ClassRegistry['Float']
    end

    it 'should be a subclass of Numeric' do
      @object_class.superclass.should == ClassRegistry['Numeric']
    end
  end
end