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

    it 'should find a more complex unused variable showing off ssa' do
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
  
  describe 'constant propagation' do
    it 'should propagate simple constants along linear code' do
      g = cfg_method <<-EOF
def foo(x)
  z = 1024
  y = z
  w = y
end
EOF
      g.should have_constant('w').with_value(1024)
      # key = g.constants.keys.find { |var| var.non_ssa_name == 'w' }
      # g.constants[key].should == 1024
    end
    
    it 'should propagate when the same variable is assigned to the same constant in branches' do
      g = cfg_method <<-EOF
def foo(x)
  if gets.size > 0
    y = 20
  else
    y = 20
  end
  z = y
end
EOF
      g.should have_constant('z').with_value(20)
      #key = g.constants.keys.find { |var| var.non_ssa_name == 'z' }
      #g.constants[key].should == 20
    end
    
    it 'should not propagate when the same variable is assigned to distinct constants in branches' do
      g = cfg_method <<-EOF
def foo(x)
  if gets.size > 0
    y = 20
  else
    y = 30
  end
  z = y
end
EOF
      g.should_not have_constant('z')
      # key = g.constants.keys.find { |var| var.non_ssa_name == 'z' }
      # key.should be nil
    end
  end
end