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
  end
end
