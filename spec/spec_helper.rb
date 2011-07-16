%x(rake build_parsers)

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

# require 'simplecov'
# require 'simplecov-gem-adapter'
# SimpleCov.start 'gem'
require 'laser'
require 'rspec'
require 'rspec/autorun'
require 'stringio'

include Laser
module Laser
  remove_const(:TESTS_ACTIVATED)
  const_set(:TESTS_ACTIVATED, true)
end

include Laser::SexpAnalysis

RSpec::Matchers.define :equal_type do |type|
  match do |orig|
    Types::subtype?(orig, type) || begin
      orig.possible_classes.all? { |klass|
        type.possible_classes.any? { |potential_super|
          klass <= potential_super
        }
      }
    end
  end
end

RSpec::Matchers.define :see_var do |name|
  match do |node|
    node.scope.sees_var?(name)
  end
  
  failure_message_for_should do |node|
    "scope #{node.scope.inspect} should have had variable #{name}, but it didn't."
  end
  
  failure_message_for_should_not do |node|
    "scope #{node.scope.inspect} should have not been able to see variable #{name}, but it can."
  end
end

RSpec::Matchers.define :parse_to do |output|
  match do |actual|
    @result = Parsers::AnnotationParser.new.parse(actual, root: :type)
    @result && (@result.type == output)
  end
  
  failure_message_for_should do |actual|
    "expected '#{actual}' to parse to #{output.inspect}, not #{@result.type.inspect}"
  end
  
  failure_message_for_should_not do |actual|
    "expected '#{actual}' to not parse to #{output.inspect}"
  end
end

RSpec::Matchers.define :correct_to do |input, output, *args|
  match do |actual|
    actual.new('(stdin)', input, *args).fix == output
  end
  
  failure_message_for_should do |actual|
    "expected '#{input}' to correct to #{output.inspect}"
  end
  
  failure_message_for_should_not do |actual|
    "expected '#{input}' to not correct to #{output.inspect}"
  end
end

RSpec::Matchers.define :warn do |input, *args|
  match do |actual|
    result = actual.new('(stdin)', input, *args).match?
    result && result != [] # empty list is also failure to find any warnings
  end
  
  failure_message_for_should do |actual|
    "expected '#{actual}' to match #{input.inspect}"
  end
  
  failure_message_for_should_not do |actual|
    "expected '#{actual}' to not match #{input.inspect}"
  end
end

RSpec.configure do |config|
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