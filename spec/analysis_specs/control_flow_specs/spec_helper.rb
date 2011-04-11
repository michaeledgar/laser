require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def cfg_builder_for(input)
  ControlFlow::GraphBuilder.new(annotate_all(input)[1][0][3])
end

RSpec::Matchers.define :have_error do |klass|
  chain :on_line do |number|
    @line = number
  end
  
  chain :with_message do |message|
    @message_matcher = message
  end
  
  match do |graph|
    graph.analyze
    
    graph.all_errors.any? do |err|
      @matches_class = err.is_a?(klass)
      @matches_line = !@line || err.line_number == @line
      @matches_message = if String === @message_matcher
                          err.message == @message_matcher
                        elsif Regexp === @message_matcher
                          err.message =~ @message_matcher
                        else
                          true
                        end
      @matches_message && @matches_line && @matches_class
    end
  end
  
  failure_message_for_should do |graph|
    result = 'expected an error that'
    result << " was of the class #{klass.name}" if !@matches_message
    result << " was on line #@line" if !@matches_line
    if !@matches_message
      result << " matches the regex #{@message_matcher}" if Regexp === @message_matcher
      result << " matches the regex #{@message_matcher}" if String === @message_matcher
    end
    result
  end
  
  failure_message_for_should_not do |graph|
    "Expected to not find any errors of class #{klass.name}"
  end
end