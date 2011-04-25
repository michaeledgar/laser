require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ControlFlow::ConstantPropagation do
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
  
  it 'should infer constants due to semantics of mismatched parallel assignments' do
    g = cfg_method <<-EOF
def foo(x)
  a, b, c = x, 10
end
EOF
    g.should have_constant('b').with_value(10)
    g.should have_constant('c').with_value(nil)
    g.should_not have_constant('a')
  end

  it 'should infer constants due to semantics of 1-to-N parallel assignment' do
    g = cfg_method <<-EOF
def foo(x)
  a = 1, (2 ** 10), 3
end
EOF
    g.should have_constant('a').with_value([1, 1024, 3])
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