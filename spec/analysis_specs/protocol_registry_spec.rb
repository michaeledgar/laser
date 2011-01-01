require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'ostruct'

describe ProtocolRegistry do
  extend AnalysisHelpers
  clean_registry

  before(:each) do
    ProtocolRegistry.protocols = []
    ProtocolRegistry.class_protocols = {}
  end
  
  describe '#add_protocol' do
    it 'adds a protocol to the main protocol list' do
      x = Object.new
      ProtocolRegistry.add_protocol x
      ProtocolRegistry.protocols.should include(x)
    end
  end
  
  describe '#add_class_protocol' do
    it 'adds a protocol to the main protocol list, and adds a shortcut in the class map' do
      x = OpenStruct.new
      x.value = OpenStruct.new
      x.value.path = 'SuperPath'
      ProtocolRegistry.add_class_protocol x
      ProtocolRegistry.protocols.should include(x)
      ProtocolRegistry.class_protocols['SuperPath'].should == x
    end
  end
  
  describe '#[]' do
    it 'looks up quick queries by class path' do
      x = OpenStruct.new
      x.value = OpenStruct.new
      x.value.path = 'SuperPath'
      ProtocolRegistry.add_class_protocol x
      ProtocolRegistry['SuperPath'].should == [x]
    end
  end
  
  describe '#query' do
    describe 'with :class_path specified' do
      it 'finds the classes in the registry with the given path' do
        x = OpenStruct.new
        x.value = OpenStruct.new
        x.value.path = 'SuperPath'
        ProtocolRegistry.add_class_protocol x
        ProtocolRegistry.query(:class_path => 'SuperPath').should == [x]
      end
    end
  end
end

describe 'ClassRegistry' do
  extend AnalysisHelpers
  clean_registry

  describe '#[]' do
    it 'finds InstanceProtocols and extracts the WoolClass appropriately' do
      ClassRegistry['Object'].should == ProtocolRegistry['Object'].first.value
      x = OpenStruct.new
      x.value = temp_class = OpenStruct.new
      x.value.path = 'SillyWilly'
      ProtocolRegistry.add_class_protocol x
      ClassRegistry['SillyWilly'].should == temp_class
    end
    
    it 'raises on failure' do
      lambda { ClassRegistry['OogaBoogaBoo'] }.should raise_error(ArgumentError)
    end
  end

  describe 'built-in classes' do
    it 'sets up Module, Class, and Object as instances of Class correctly' do
      ClassRegistry['Object'].object.class_used.should == ClassRegistry['Class']
      ClassRegistry['Module'].object.class_used.should == ClassRegistry['Class']
      ClassRegistry['Class'].object.class_used.should == ClassRegistry['Class']
    end
    it "sets up Module, Class, and Object's hierarchy" do
      ClassRegistry['Object'].superclass.should == nil
      ClassRegistry['Module'].superclass.should == ClassRegistry['Object']
      ClassRegistry['Class'].superclass.should == ClassRegistry['Module']
    end
  end
end