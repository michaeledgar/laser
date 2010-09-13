require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "wool"
    gem.summary = %Q{Style-focused linter for Ruby code.}
    gem.description = %Q{Unlike existing lint tools, wool intends solely to examine Ruby code for style issues.}
    gem.email = "michael.j.edgar@dartmouth.edu"
    gem.homepage = "http://github.com/michaeledgar/wool"
    gem.authors = ["Michael Edgar"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "yard", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec' << 'test'
  spec.spec_files = FileList['spec/**/*_spec.rb'] + FileList['test/**/test_*.rb']
  spec.rcov = true
end

require 'cucumber'
require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
end

begin
  require 'wool'
  Wool::Rake::WoolTask.new(:wool) do |wool|
    wool.libs << 'lib' << 'spec'
    wool.using << Wool::LineLengthMaximum(100) << Wool::LineLengthWarning(80) << Wool::SemicolonWarning
    wool.options = '--debug'
  end
rescue LoadError => err
  task :wool do
    abort 'Wool is not available. In order to run wool, you must: sudo gem install wool'
  end
end

task :rebuild => [:gemspec, :build, :install] do
  %x(rake wool)
end

task :spec => :check_dependencies

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort 'YARD is not available. In order to run yardoc, you must: sudo gem install yard'
  end
end
