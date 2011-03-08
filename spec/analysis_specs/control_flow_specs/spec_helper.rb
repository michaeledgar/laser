require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def cfg_builder_for(input)
  ControlFlow::GraphBuilder.new(annotate_all(input)[1][0][3])
end