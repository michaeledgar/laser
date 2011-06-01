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
    g.yield_arity.should == Set[]
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
    g.yield_arity.should == Set[]
  end

  it 'should recognize simple required-yield methods' do
    g = cfg_method <<-EOF
def tap
yield self
self
end
EOF
    g.yield_type.should be :required
    g.yield_arity.should == Set[1]
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
    g.yield_arity.should == Set[0]
  end
  ['block_given?', 'defined?(yield)', 'defined?(yield($., *$*))', 'Proc.new'].each do |guard|
    it "denotes the method optional when yield is guarded by #{guard}" do
      g = cfg_method <<-EOF
  def one
    if #{guard}
      yield 1
    else
      1
    end
  end
  EOF
      g.yield_type.should be :optional
      g.yield_arity.should == Set[1]
    end

    it "denotes the method foolish when yield is not guarded by #{guard}, but the block is unused when given" do
      g = cfg_method <<-EOF
  def one
    if #{guard}
      1
    else
      yield 1
    end
  end
  EOF
      g.yield_type.should be :foolish
      g.yield_arity.should == Set[]
    end
  end

  it 'denotes the method optional when the explicit block arg is checked vs. nil' do
    g = cfg_method <<-EOF
def one(&blk)
  if blk != nil
    yield 1
    yield(1, 2)
  else
    1
  end
end
EOF
    g.yield_type.should be :optional
    g.yield_arity.should == Set[1, 2]
  end

  it 'denotes the method optional when the explicit block arg is checked vs. nil and called explicitly' do
    g = cfg_method <<-EOF
def one(&blk)
  if blk != nil
    blk.call(2, 3)
  else
    1
  end
end
EOF
    g.yield_type.should be :optional
    g.yield_arity.should == Set[2]
  end

  it 'denotes the method required when the explicit block arg is not checked vs. nil and called explicitly' do
    g = cfg_method <<-EOF
def one(&blk)
  blk.call(2, 3)
  1
end
EOF
    g.yield_type.should be :required
    g.yield_arity.should == Set[2]
  end

  it 'denotes the method foolish when the explicit block arg is checked vs. nil and called explicitly' do
    g = cfg_method <<-EOF
def one(&blk)
  if blk == nil
    blk.call(2, 3)
  end
  1
end
EOF
    g.yield_type.should be :foolish
    g.yield_arity.should == Set[]
  end
  
  it 'denotes the method optional when the Proc.new block arg is checked vs. nil and called explicitly' do
    g = cfg_method <<-EOF
def one
  blk = Proc::new
  if blk != nil
    blk.call(2, 3)
  else
    1
  end
end
EOF
    g.yield_type.should be :optional
    g.yield_arity.should == Set[2]
  end

  it 'denotes the method required when the Proc.new block arg is not checked vs. nil and called explicitly' do
    g = cfg_method <<-EOF
def one
  blk = Proc::new
  blk.call(2, 3)
  1
end
EOF
    g.yield_type.should be :required
    g.yield_arity.should == Set[2]
  end

  it 'denotes the method foolish when the Proc.new block arg is checked vs. nil and called explicitly' do
    g = cfg_method <<-EOF
def one
  blk = Proc::new
  if blk == nil
    blk.call(2, 3)
  end
  1
end
EOF
    g.yield_type.should be :foolish
    g.yield_arity.should == Set[]
  end

  it 'denotes the method ignored when the explicit block arg is never called' do
    g = cfg_method <<-EOF
def one(&blk)
  result = blk.nil? ? 5 : 10
  result ** result
end
EOF
    g.yield_type.should be :ignored
    g.yield_arity.should == Set[]
  end

  it 'is not confused by sending .call to other arguments' do
    g = cfg_method <<-EOF
def one(other_arg, &blk)
  other_arg.call(5)
end
EOF
    g.yield_type.should be :ignored
  end

  it 'uses SSA information to find aliases for .call on the block' do
    g = cfg_method <<-EOF
def one(other_arg, &blk)
  if gets.size > 2
    other_arg = blk
  end
  other_arg.call(2)
end
EOF
    g.yield_type.should be :required
  end

  %w(LocalJumpError StandardError Exception Object Kernel BasicObject).each do |exc|
    it "denotes the method optional when yield is guarded by rescue of #{exc}" do
      g = cfg_method <<-EOF
def one
  yield 1
  4
rescue #{exc}
  2
end
EOF
      g.yield_type.should be :optional
      g.yield_arity.should == Set[1]
    end
  end

  it 'denotes the method optional when yield is guarded by a rescue modifier' do
    g = cfg_method <<-EOF
def one
  yield 1 rescue 2
end
EOF
    g.yield_type.should be :optional
    g.yield_arity.should == Set[1]
  end

  it "denotes the method required if the yield is guarded by a non-matching rescue" do
    g = cfg_method <<-EOF
def one
  yield 1
  4
rescue RuntimeError
  2
end
EOF
    g.yield_type.should be :required
    g.yield_arity.should == Set[1]
  end
end
