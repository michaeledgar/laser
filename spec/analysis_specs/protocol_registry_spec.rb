require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'ostruct'

describe SexpAnalysis::ProtocolRegistry do
  before(:each) do
    @backup_all = SexpAnalysis::ProtocolRegistry.protocols.dup
    @backup_map = SexpAnalysis::ProtocolRegistry.class_protocols.dup
    
    SexpAnalysis::ProtocolRegistry.protocols = []
    SexpAnalysis::ProtocolRegistry.class_protocols = {}
  end
  
  after(:each) do
    SexpAnalysis::ProtocolRegistry.protocols = @backup_all
    SexpAnalysis::ProtocolRegistry.class_protocols = @backup_map
  end
  
  context '#add_protocol' do
    it 'adds a protocol to the main protocol list' do
      x = Object.new
      SexpAnalysis::ProtocolRegistry.add_protocol x
      SexpAnalysis::ProtocolRegistry.protocols.should include(x)
    end
  end
  
  context '#add_class_protocol' do
    it 'adds a protocol to the main protocol list, and adds a shortcut in the class map' do
      x = OpenStruct.new
      x.class_used = OpenStruct.new
      x.class_used.path = 'SuperPath'
      SexpAnalysis::ProtocolRegistry.add_class_protocol x
      SexpAnalysis::ProtocolRegistry.protocols.should include(x)
      SexpAnalysis::ProtocolRegistry.class_protocols['SuperPath'].should == x
    end
  end
  
  context '#[]' do
    it 'looks up quick queries by class path' do
      x = OpenStruct.new
      x.class_used = OpenStruct.new
      x.class_used.path = 'SuperPath'
      SexpAnalysis::ProtocolRegistry.add_class_protocol x
      SexpAnalysis::ProtocolRegistry['SuperPath'].should == [x]
    end
  end
  
  context '#query' do
    context 'with :class_path specified' do
      it 'finds the classes in the registry with the given path' do
        x = OpenStruct.new
        x.class_used = OpenStruct.new
        x.class_used.path = 'SuperPath'
        SexpAnalysis::ProtocolRegistry.add_class_protocol x
        SexpAnalysis::ProtocolRegistry.query(:class_path => 'SuperPath').should == [x]
      end
    end
  end
end