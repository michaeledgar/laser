$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'wool'
require 'spec'
require 'spec/autorun'
require 'stringio'

module Wool
  module RSpec
    module Matchers
      class Warns
        def initialize(input, *args)
          @input, @args = input, args
        end
    
        def matches?(actual)
          @class = actual
          @class.new('(stdin)', @input, *@args).match?
        end

        def failure_message
          "expected '#{@actual}' to match #{@input.inspect}"
        end

        def negative_failure_message
          "expected '#{@actual}' to not match #{@input.inspect}"
        end
      end

      def warn(input, *args)
        Warns.new(input, *args)
      end
    end
  end
end

Spec::Runner.configure do |config|
  config.include(Wool::RSpec::Matchers)
end

def with_examples(*args)
  args.each do |arg|
    yield arg
  end
end

def swizzling_io
  old_stdout, $stdout = $stdout, StringIO.new
  yield
  return $stdout.string
ensure
  $stdout = old_stdout
end