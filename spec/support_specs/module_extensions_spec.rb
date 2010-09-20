require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::LexicalAnalysis do
  before do
    @class = Class.new do
      extend Wool::ModuleExtensions
      cattr_reader :read1, :read2
      cattr_writer :write1, :write2
      cattr_accessor :both1, :both2
      cattr_accessor_with_default :arr1, []
    end
  end
  
  describe '#cattr_reader' do
    it 'creates reading methods for the given variables' do
      @class.__send__(:instance_variable_set, :@read1, 'hello')
      @class.read1.should == 'hello'
      @class.__send__(:instance_variable_set, :@read2, 5)
      @class.read2.should == 5
    end
  end
  
  describe '#cattr_writer' do
    it 'creates writing methods for the given variables' do
      @class.write1 = 'hello'
      @class.__send__(:instance_variable_get, :@write1).should == 'hello'
      @class.write2 = 5
      @class.__send__(:instance_variable_get, :@write2).should == 5
    end
  end
  
  describe '#cattr_accessor' do
    it 'creates reading and writing methods for the given variables' do
      @class.both1 = 'hello'
      @class.both1.should == 'hello'
      @class.__send__(:instance_variable_get, :@both1).should == 'hello'
      @class.__send__(:instance_variable_set, :@both1, 'world')
      @class.both1.should == 'world'
      @class.both2 = 5
      @class.both2.should == 5
      @class.__send__(:instance_variable_get, :@both2).should == 5
      @class.__send__(:instance_variable_set, :@both2, 10)
      @class.both2.should == 10
    end
  end
  
  describe '#cattr_accessor_with_default' do
    it 'creates reading and writing methods, but defaults the ivar value' do
      @class.arr1.should == []
      @class.__send__(:instance_variable_get, :@arr1).should == []
      @class.arr1.should == [] # second invocation, after default value set
      @class.arr1 = [1, 2]
      @class.arr1.should == [1, 2]
      @class.__send__(:instance_variable_get, :@arr1).should == [1, 2]
    end
  end
end