require_relative '../spec_helper'

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

RSpec::Matchers.define :have_constant do |name|
  chain :with_value do |value|
    @value = value
  end
  
  match do |graph|
    graph.constants.keys.find do |var|
      next unless var.non_ssa_name == name
      @constant = var
      @value ||= nil
      if @value
        @constant && (@constant.value == @value)
      else
        @constant
      end
    end
  end
  
  failure_message_for_should do |graph|
    if !@constant
      "Expected variable '#{name}' to be inferred as a constant, but it was not."
    elsif @constant.value != @value
      "Expected variable '#{name}' to have value #{@value}, but it was #{@constant.value}."
    else
      "UNEXPECTED FAILURE?!"
    end
  end
  
  failure_message_for_should_not do |graph|
    if @constant && @constant.value == @value
      "Expected variable '#{name}' to not have value #{@value}, but it was #{@constant.value}."
    elsif @constant
      "Expected variable '#{name}' to not be inferred as a constant, but it was."
    else
      "UNEXPECTED FAILURE?!"
    end
  end
end


include Laser::SexpAnalysis
def annotate_all_cfg(body)
  inputs = [['(stdin)', body]]
  inputs.map! do |filename, text|
    [filename, text, Sexp.new(RipperPlus.sexp(text), filename, text)]
  end
  Annotations.apply_inherited_attributes(inputs)
  inputs[0][2]
end
def cfg(input)
  cfg_builder = ControlFlow::GraphBuilder.new(annotate_all_cfg(input))
  graph = cfg_builder.build
  graph.analyze
  graph
end
def cfg_method(input)
  method_tree = annotate_all_cfg(input)
  body = method_tree.find_type(:bodystmt)
  cfg_builder = ControlFlow::GraphBuilder.new(
      body, Signature.arg_list_for_arglist(body.prev))
  graph = cfg_builder.build
  graph.analyze
  graph
end
