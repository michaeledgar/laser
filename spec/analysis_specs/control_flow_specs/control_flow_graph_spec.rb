require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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
    y = z  # this y is used as return value
  else
    y = z * 2
    puts y
  end
end
EOF
      g.should have_error(Laser::UnusedVariableWarning).on_line(4).with_message(/\b y \b/x)
    end
    
    it 'should see when a variable is assigned and used to compute only unused vars' do
      g = cfg_method <<-EOF
def foo(x)
  z = gets * 10
  d = z * 2
  a = d
  puts z
  nil
end
EOF
      g.should have_error(Laser::UnusedVariableWarning).on_line(3).with_message(/\b d \b/x)
      g.should have_error(Laser::UnusedVariableWarning).on_line(4).with_message(/\b a \b/x)
      g.should_not have_error(Laser::UnusedVariableWarning).with_message(/\b z \b/x)
    end

    it 'should ignore SSA variables assigned and used to compute only unused vars' do
      g = cfg_method <<-EOF
def foo(x)
  z = gets * 10
  if z.size > 3
    d = z * 2
    c = z
  else
    d = z * 10
    c = 30
  end
  j = d
  c
end
EOF

      g.should have_error(Laser::UnusedVariableWarning).on_line(4).with_message(/\b d \b/x)
      g.should have_error(Laser::UnusedVariableWarning).on_line(7).with_message(/\b d \b/x)
      g.should have_error(Laser::UnusedVariableWarning).on_line(10).with_message(/\b j \b/x)
    end
    
    it 'is improved by constant propagation' do
      g = cfg_method <<-EOF
def foo(x)
  z = (10 ** 5).to_s(5)
  if z == "11200000"
    d = z * 2
    c = z
  else
    d = z * 10
    c = 30
  end
  j = d
  c
end
EOF

      g.should have_error(Laser::UnusedVariableWarning).on_line(4).with_message(/\b d \b/x)
      g.should have_error(Laser::UnusedVariableWarning).on_line(7).with_message(/\b d \b/x)
      g.should have_error(Laser::UnusedVariableWarning).on_line(8).with_message(/\b c \b/x)
      g.should have_error(Laser::UnusedVariableWarning).on_line(10).with_message(/\b j \b/x)
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
    end
    
    it 'should propagate manipulation of hashes' do
      g = cfg_method <<-EOF
def foo(x)
  z = {a: 3, 'd' => 4.5}
  j = z[:a]
  arr = z.values
end
EOF
      g.should have_constant('j').with_value(3)
      g.should have_constant('arr').with_value([3, 4.5])
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
    end
    
    it 'should ignore branches on false' do
      g = cfg_method <<-EOF
def foo(x)
  if false
    y = 40
  else
    y = 30
  end
  z = y
end
EOF
      g.should have_constant('z').with_value(30)
    end

    it 'should ignore else branches on true' do
      g = cfg_method <<-EOF
def foo(x)
  if true
    y = 40
  else
    y = 30
  end
  z = y
end
EOF
      g.should have_constant('z').with_value(40)
    end
    
    it 'should ignore branches on constant variables' do
      g = cfg_method <<-EOF
def foo(x)
  a = true ? 30 : false
  if a
    y = 40
  else
    y = 30
  end
  z = y
end
EOF
      g.should have_constant('z').with_value(40)
    end
    
    it 'should ignore branches on fixnum equality' do
      g = cfg_method <<-EOF
def foo(x)
  a = true ? 30 : false
  if a == 30
    y = 40
  else
    y = 30
  end
  z = y
end
EOF
      g.should have_constant('z').with_value(40)
    end
    
    it 'should calculate bignum arithmetic' do
      g = cfg_method <<-EOF
def foo(x)
  a = 3 * (1 << 3)
  b = a ** a
  c = b - a
end
EOF
      g.should have_constant('c').with_value(1333735776850284124449081472843752)
    end
    
    it 'should handle string constants' do
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
      g.should have_constant('a').with_value(3)
    end
    
    it 'should calculate 0 * (varying numeric) = 0' do
      g = cfg_method <<-EOF
def foo(x)
  if gets.size > 0
    a = 5
  else
    a = 10.11
  end
  b = 0 * a
  c = a * 0
end
EOF
      g.should have_constant('b').with_value(0)
      g.should have_constant('c').with_value(0)
    end

    it 'should calculate (varying string) * 0 = ""' do
      g = cfg_method <<-EOF
def foo(x)
  if gets.size > 0
    a = 'hello'
  else
    a = 'world'
  end
  c = a * 0
end
EOF
      g.should have_constant('c').with_value('')
    end

    it 'should calculate (varying array) * 0 = []' do
      g = cfg_method <<-EOF
def foo(x)
  if gets.size > 0
    a = [1, 'hello']
  else
    a = [2, 'world', 'thing']
  end
  c = a * 0
end
EOF
      g.should have_constant('c').with_value([])
    end

    it 'should calculate 0 * (varying numeric | string) = varying' do
      g = cfg_method <<-EOF
def foo(x)
  if gets.size > 0
    a = 5
  else
    a = 'hello'
  end
  b = 0 * a
  c = a * 0
end
EOF
      g.should_not have_constant('b')
      g.should_not have_constant('c')
    end
    
    it 'should calculate (varying numeric) ** 0 = 1' do
      g = cfg_method <<-EOF
def foo(x)
  if gets.size > 0
    a = 5.93
  else
    a = 10
  end
  c = a ** 0
end
EOF
      g.should have_constant('c').with_value(1)
    end
    
    it 'should calculate (varying numeric | string) ** 0 = varying' do
      g = cfg_method <<-EOF
def foo(x)
  if gets.size > 0
    a = 5
  else
    a = 'hello'
  end
  c = a ** 0
end
EOF
      g.should_not have_constant('c')
    end

    it 'should calculate 1 ** (varying numeric) = 1' do
      g = cfg_method <<-EOF
def foo(x)
  if gets.size > 0
    a = 5
  else
    a = 10.2
  end
  c = 1 ** a
end
EOF
      g.should have_constant('c').with_value(1)
    end

    it 'should calculate 1 ** (varying numeric | string) = varying' do
      g = cfg_method <<-EOF
def foo(x)
  if gets.size > 0
    a = 5
  else
    a = 'hello'
  end
  c = 1 ** a
end
EOF
      g.should_not have_constant('c')
    end
    
    it 'should infer that assignments after a guaranteed raise do not affect CP' do
      g = cfg_method <<-EOF
def foo(x)
  if gets.size > 0
    a = 5
  else
    raise 'arrrrrrr'
    a = 10.2
  end
  c = a
end
EOF
      g.should have_constant('c').with_value(5)
    end

    it 'should infer that assignments after a guaranteed raise (by CP simulation) do not affect CP' do
      g = cfg_method <<-EOF
def foo(x)
  if gets.size > 0
    a = 5
  else
    a = 5 / 0
  end
  c = a
end
EOF
      g.should have_constant('c').with_value(5)
    end
  end

  describe 'yield-type inference' do
    it 'should recognize non-yielding methods' do
      g = cfg_method <<-EOF
def foo(x)
  y = gets() * 2
  z = y
  c = z * z
end
EOF
      g.yield_type.should be :ignored
    end

    it 'should recognize non-yielding methods via CP' do
      g = cfg_method <<-EOF
def foo(x)
  x = 2 ** 16
  if x == 65536
    puts x
  else
    yield
  end
end
EOF
      g.yield_type.should be :ignored
    end

    it 'should recognize simple required-yield methods' do
      g = cfg_method <<-EOF
def tap
  yield self
  self
end
EOF
      g.yield_type.should be :required
    end

    it 'denotes the method required when a branch is unprovable' do
      g = cfg_method <<-EOF
def one
  if gets.size < 0
    yield
  else
    1
  end
end
EOF
      g.yield_type.should be :required
    end

    it 'denotes the method optional when yield is guarded by block_given?' do
      g = cfg_method <<-EOF
def one
  if block_given?
    yield 1
  else
    1
  end
end
EOF
      g.yield_type.should be :optional
    end
    
    pending 'denotes the method optional when yield is guarded by a guaranteed rescue'
  end
end