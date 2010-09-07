$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'wool'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  
end

def with_examples(*args)
  args.each do |arg|
    yield arg
  end
end