require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ControlFlow::UnreachabilityAnalysis do
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
  z = y.foo
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

  it 'should find code that never runs due to constant propagation' do
    g = cfg_method <<-EOF
def foo(x)
y = 'hello' * 3
if y == 'hellohellohello'
  puts gets
  z = 3
else
  z = 10
end
a = z
end
EOF
    g.should have_error(Laser::DeadCodeWarning).on_line(7)
  end
end
