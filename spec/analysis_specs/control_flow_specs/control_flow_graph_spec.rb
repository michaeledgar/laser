require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

include Laser::SexpAnalysis
def annotate_all(body)
  Annotations.annotate_inputs([['(stdin)', body]]).first[1]
end
def cfg(input)
  cfg_builder = ControlFlow::GraphBuilder.new(annotate_all(input))
  cfg_builder.build
end
def cfg_method(input)
  cfg_builder = ControlFlow::GraphBuilder.new(
      annotate_all(input).deep_find { |node| node.type == :bodystmt })
  cfg_builder.build
end

describe ControlFlow::ControlFlowGraph do  
  describe 'unreachable code discovery' do
    it 'should find code that follows explicit return' do
      g = cfg_method <<-EOF
def foo(x)
  y = gets() * 2
  return y
  p y
end
EOF
      g.should have_error(Laser::DeadCodeWarning).on_line(4)
    end

    %w{next break redo}.each do |keyword|
      it "should find code that follows a #{keyword}" do
        g = cfg_method <<-EOF
def foo(x)
  while y = gets() * 2
    p y
    #{keyword}
    y.foo
  end
end
EOF
        g.should have_error(Laser::DeadCodeWarning).on_line(5)
      end
    end
    
    it 'should find code that follows an if/else/elsif in which each branch jumps' do
      g = cfg_method <<-EOF
def foo(x)
  y = gets() * 2
  if y.size > 10
    return y
  elsif y.size < 10
    return y[0..4]
  else
    return 'hello'
  end
  puts y
end
EOF
      g.should have_error(Laser::DeadCodeWarning).on_line(10)
    end
  end
  
  describe 'unused variable detection' do
    it 'should find a simple unused variable' do
      g = cfg_method <<-EOF
def foo(x)
  y = gets() * 2
  z = y
  c = z * z
end
EOF
      g.should have_error(Laser::UnusedVariableWarning).on_line(4).with_message(/\b c \b/x)
    end

    it 'should find a more complex unused variable' do
      g = cfg_method <<-EOF
def foo(x)
  z = gets * 10
  if z.size > 50
    y = z
  else
    y = z * 2
    puts y
  end
end
EOF
      g.should have_error(Laser::UnusedVariableWarning).on_line(4).with_message(/\b y \b/x)
    end
  end
end