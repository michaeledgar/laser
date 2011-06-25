require_relative 'spec_helper'
require 'rubygems'
require 'rake'
require 'tmpdir'
require 'laser/rake/task'

describe Laser::Rake::LaserTask do
  describe '#initialize' do
    it 'yields to allow setting :libs and :extras' do
      task_name = "temptask1-#{rand(65329)}".to_sym
      task = Laser::Rake::LaserTask.new(task_name) do |laser|
        laser.libs = "LOL"
        laser.extras = "hai"
      end
      task.settings.libs.should == "LOL"
      task.settings.extras.should == "hai"
    end

    it 'creates a Rake task with the given name that calls #run' do
      task_name = "temptask2_#{rand(65000)}".to_sym
      task = Laser::Rake::LaserTask.new(task_name)
      Rake::Task[task_name].should_not be_nil
      task.should_receive(:run)
      Rake::Task[task_name].invoke
    end

    it 'allows you to specify which warnings to use' do
      task_name = "temptask3_#{rand(65000)}".to_sym
      task = Laser::Rake::LaserTask.new(task_name) do |laser|
        laser.using << :one << :two
      end
      task.settings.using.should == [:one, :two]
    end

    it 'defaults to using all warnings' do
      task_name = "temptask4_#{rand(65000)}".to_sym
      task = Laser::Rake::LaserTask.new(task_name) do |laser|
      end
      task.settings.using.should == [:all]
    end
  end

  describe '#run' do
    it 'searches the listed libraries for files' do
      Dir.should_receive(:[]).with('lib/**/*.rb').and_return([])
      Dir.should_receive(:[]).with('spec/**/*.rb').and_return([])
      task = Laser::Rake::LaserTask.new("temptask3-#{rand(65329)}".to_sym) do |laser|
        laser.libs << 'lib' << 'spec'
      end
      swizzling_io { task.run }
    end

    it 'scans the matching files' do
      test_file = File.open(File.join(Dir.tmpdir, 'test_input'), 'w') do |fp|
        fp << 'a + b  '
      end
      Dir.should_receive(:[]).with('lib/**/*.rb').and_return([File.join(Dir.tmpdir, 'test_input')])
      Dir.should_receive(:[]).with('spec/**/*.rb').and_return([])
      task = Laser::Rake::LaserTask.new("temptask4-#{rand(65329)}".to_sym) do |laser|
        laser.libs << 'lib' << 'spec'
      end
      printout = swizzling_io { task.run }
      printout.should =~ /whitespace/
      printout.should =~ /1 are fixable/
    end
  end
end