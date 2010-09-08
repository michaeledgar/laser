require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rubygems'
require 'rake'
require 'wool/rake/task'

describe Wool::Rake::WoolTask do
  context '#initialize' do
    it 'yields to allow setting :libs and :extras' do
      task_name = "temptask1-#{rand(65329)}".to_sym
      task = Wool::Rake::WoolTask.new(task_name) do |wool|
        wool.libs = "LOL"
        wool.extras = "hai"
      end
      task.settings.libs.should == "LOL"
      task.settings.extras.should == "hai"
    end
    
    it 'creates a Rake task with the given name that calls #run' do
      task_name = "temptask2_#{rand(65000)}".to_sym
      task = Wool::Rake::WoolTask.new(task_name)
      Rake::Task[task_name].should_not be_nil
      task.should_receive(:run)
      Rake::Task[task_name].invoke
    end
  end
end
