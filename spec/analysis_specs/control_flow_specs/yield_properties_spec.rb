require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ControlFlow::YieldProperties do
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


  it 'denotes the method optional when yield is guarded by guaranteed rescue' do
    g = cfg_method <<-EOF
def one
  yield 1
  4
rescue LocalJumpError
  2
end
EOF
    g.yield_type.should be :optional
  end
end