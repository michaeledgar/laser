%x(rake build_parsers)

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'simplecov'
require 'simplecov-gem-adapter'
SimpleCov.start 'gem'
require 'wool'
require 'rspec'
require 'rspec/autorun'
require 'stringio'

class Object
  def debug_print
    p self
    self
  end
end

include Wool
module Wool
  remove_const(:TESTS_ACTIVATED)
  const_set(:TESTS_ACTIVATED, true)
  module RSpec
    module Matchers
      # Matcher for checking if #match? returns trues
      class Warns
        def initialize(input, *args)
          @input, @args = input, args
        end

        def matches?(actual)
          @class = actual
          result = @class.new('(stdin)', @input, *@args).match?
          result && result != [] # empty list is also failure to find any warnings
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

      # Matcher for comparing input/output of #fix
      class CorrectsTo
        def initialize(input, output, *args)
          @input, @output, @args = input, output, args
        end

        def matches?(actual)
          @class = actual
          @class.new('(stdin)', @input, *@args).fix == @output
        end

        def failure_message
          "expected '#{@input}' to correct to #{@output.inspect}"
        end

        def negative_failure_message
          "expected '#{@input}' to not correct to #{@output.inspect}"
        end
      end

      def correct_to(input, output, *args)
        CorrectsTo.new(input, output, *args)
      end
      
      # Matcher for parsing type annotations
      class ParsesTo
        def initialize(output)
          @output = output
        end

        def matches?(actual)
          @input = actual
          @result = Parsers::AnnotationParser.new.parse(actual)
          @result && @result.constraints == @output && @result.type.constraints == Set.new(@output)
        end

        def failure_message
          "expected '#{@input}' to parse to #{@output.inspect}, not #{@result.constraints.inspect}"
        end

        def negative_failure_message
          "expected '#{@input}' to not parse to #{@output.inspect}"
        end
      end

      def parse_to(output)
        ParsesTo.new(output)
      end
      
      # Matcher for checking if a scope sees a variable
      class SeesVariable
        def initialize(named)
          @name = named
        end

        def matches?(node)
          @node = node
          begin
            node.scope.lookup(@name)
            return true
          rescue Scope::ScopeLookupFailure
            return false
          end
        end

        def failure_message
          "scope #{@node.scope.inspect} should have had variable #{@name}, but it didn't."
        end

        def negative_failure_message
          "scope #{@node.scope.inspect} should have not been able to see variable #{@name}, but it can."
        end
      end

      def see_var(named)
        SeesVariable.new(named)
      end
    end
  end
end

RSpec.configure do |config|
  config.include(Wool::RSpec::Matchers)
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

def many_mocks(n)
  ([nil] * n).fill { mock }
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

def swizzling_stdin
  old_stdin, $stdin = $stdin, StringIO.new
  yield $stdin
  return $stdin.string
ensure
  $stdin = old_stdin
end