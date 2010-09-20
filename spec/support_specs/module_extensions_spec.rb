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
    it 'creates reading methods for the variable' do
      @class.__send__(:instance_variable_set, :@read1, 'hello')
      @class.read1.should == 'hello'
      @class.__send__(:instance_variable_set, :@read2, 5)
      @class.read2.should == 5
    end
  end
  
  describe '#cattr_writer' do
    it 'creates writing methods for the variable' do
      @class.write1 = 'hello'
      @class.__send__(:instance_variable_get, :@write1).should == 'hello'
      @class.write2 = 5
      @class.__send__(:instance_variable_get, :@write2).should == 5
    end
  end
end