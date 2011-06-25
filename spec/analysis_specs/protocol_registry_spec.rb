require_relative 'spec_helper'
require 'ostruct'

describe ProtocolRegistry do
  extend AnalysisHelpers
  clean_registry

  before(:each) do
    ProtocolRegistry.class_protocols = {}
  end
  
  describe '#add_class' do
    it 'adds a protocol to the main protocol list, and adds a shortcut in the class map' do
      x = OpenStruct.new
      x.path = 'SuperPath'
      ProtocolRegistry.add_class x
      ProtocolRegistry.class_protocols['SuperPath'].should == x
    end
  end
  
  describe '#[]' do
    it 'looks up quick queries by class path' do
      x = OpenStruct.new
      x.path = 'SuperPath'
      ProtocolRegistry.add_class x
      ProtocolRegistry['SuperPath'].should == [x]
    end
  end
end

describe 'ClassRegistry' do
  extend AnalysisHelpers
  clean_registry

  describe '#[]' do
    it 'finds classes with the given name' do
      ClassRegistry['Object'].should == ProtocolRegistry['Object'].first
      x = OpenStruct.new
      x.path = 'SillyWilly'
      ProtocolRegistry.add_class x
      ClassRegistry['SillyWilly'].should == x
    end
    
    it 'raises on failure' do
      expect { ClassRegistry['Hiybbprqag'] }.to raise_error(ArgumentError)
    end
  end

  describe 'built-in classes' do
    it 'sets up Module, Class, and Object as instances of Class correctly' do
      ClassRegistry['BasicObject'].binding.class_used.should == ClassRegistry['BasicObject'].singleton_class
      ClassRegistry['Object'].binding.class_used.should == ClassRegistry['Object'].singleton_class
      ClassRegistry['Module'].binding.class_used.should == ClassRegistry['Module'].singleton_class
      ClassRegistry['Class'].binding.class_used.should == ClassRegistry['Class'].singleton_class
    end
    it "sets up Module, Class, and Object's hierarchy" do
      ClassRegistry['BasicObject'].superclass.should == nil
      ClassRegistry['Object'].superclass.should == ClassRegistry['BasicObject']
      ClassRegistry['Module'].superclass.should == ClassRegistry['Object']
      ClassRegistry['Class'].superclass.should == ClassRegistry['Module']
    end
  end
end