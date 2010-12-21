require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'ostruct'

describe ProtocolRegistry do
  before(:each) do
    @backup_all = ProtocolRegistry.protocols.dup
    @backup_map = ProtocolRegistry.class_protocols.dup
    
    ProtocolRegistry.protocols = []
    ProtocolRegistry.class_protocols = {}
  end
  
  after(:each) do
    ProtocolRegistry.protocols = @backup_all
    ProtocolRegistry.class_protocols = @backup_map
  end
  
  context '#add_protocol' do
    it 'adds a protocol to the main protocol list' do
      x = Object.new
      ProtocolRegistry.add_protocol x
      ProtocolRegistry.protocols.should include(x)
    end
  end
  
  context '#add_class_protocol' do
    it 'adds a protocol to the main protocol list, and adds a shortcut in the class map' do
      x = OpenStruct.new
      x.class_used = OpenStruct.new
      x.class_used.path = 'SuperPath'
      ProtocolRegistry.add_class_protocol x
      ProtocolRegistry.protocols.should include(x)
      ProtocolRegistry.class_protocols['SuperPath'].should == x
    end
  end
  
  context '#[]' do
    it 'looks up quick queries by class path' do
      x = OpenStruct.new
      x.class_used = OpenStruct.new
      x.class_used.path = 'SuperPath'
      ProtocolRegistry.add_class_protocol x
      ProtocolRegistry['SuperPath'].should == [x]
    end
  end
  
  context '#query' do
    context 'with :class_path specified' do
      it 'finds the classes in the registry with the given path' do
        x = OpenStruct.new
        x.class_used = OpenStruct.new
        x.class_used.path = 'SuperPath'
        ProtocolRegistry.add_class_protocol x
        ProtocolRegistry.query(:class_path => 'SuperPath').should == [x]
      end
    end
  end
end

describe 'ClassRegistry' do
  
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