require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = 'wool'
    gem.summary = %Q{Analysis and linting tool for Ruby.}
    gem.description = %Q{Wool is an advanced static analysis tool for Ruby.}
    gem.email = 'michael.j.edgar@dartmouth.edu'
    gem.homepage = 'http://github.com/michaeledgar/wool'
    gem.authors = ['Michael Edgar']
    gem.add_development_dependency 'rspec', '~> 2.3'
    gem.add_development_dependency 'yard', '>= 0'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :rcov => :default

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/test*.rb']
  t.verbose = true
end

require 'cucumber'
require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
end

require 'metric_fu'

if true
  begin
    require 'wool'
    Wool::Rake::WoolTask.new(:wool) do |wool|
      wool.libs << 'lib' << 'spec'
      wool.using << :all << Wool::LineLengthMaximum(100) << Wool::LineLengthWarning(80)
      wool.options = '--debug --fix'
      wool.fix << Wool::ExtraBlankLinesWarning << Wool::ExtraWhitespaceWarning << Wool::LineLengthWarning(80)
    end
  rescue LoadError => err
    task :wool do
      abort 'Wool is not available. In order to run wool, you must: sudo gem install wool'
    end
  end
end

task :rebuild => [:gemspec, :build, :install] do
  %x(rake wool)
end

task :spec => :check_dependencies

task :default => [:spec, :test]

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort 'YARD is not available. In order to run yardoc, you must: sudo gem install yard'
  end
end
