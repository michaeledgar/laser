require_relative 'spec_helper'

describe 'Tuple misuse inference' do
  it 'should find code that has statically too few mlhs for mrhs' do
    g = cfg_method <<-EOF
def foo(x)
  a, b, c, d = x, x
end
EOF
    g.should have_error(Laser::UnassignedLHSError).on_line(2).with_message(/\(c\)/)
    g.should have_error(Laser::UnassignedLHSError).on_line(2).with_message(/\(d\)/)
  end

  it 'should find code that has statically too many mlhs for mrhs' do
    g = cfg_method <<-EOF
def foo(x)
  a, d = x, x, x
end
EOF
    g.should have_error(Laser::DiscardedRHSError).on_line(2)
  end

  it 'should find statically useless LHS splats' do
g = cfg_method <<-EOF
def foo(x)
  a, *b, d = x, x
end
EOF
    g.should have_error(Laser::UnassignedLHSError).on_line(2).with_message(/\(b\)/)
  end

  it 'should find statically useless LHS unnamed splats and report them differently' do
g = cfg_method <<-EOF
def foo(x)
  a, *, d = x, x
end
EOF
    g.should have_error(Laser::UnassignedLHSError).on_line(2).with_message(/Unnamed LHS/i)
  end

  it 'should find statically discarded RHS splats' do
g = cfg_method <<-EOF
def foo(x)
  a, b, c = x, x, x, *x
end
EOF
    g.should have_error(Laser::DiscardedRHSError).on_line(2).with_message(/splat/i)
  end

  it 'should find dynamically-proven unassigned LHS vars' do
    g = cfg <<-EOF
class TupleMisuse1
  def foo(x)
    a, b, c = bar(x)
  end
  def bar(x)
    [x, x]
  end
end
TupleMisuse1.new.foo(gets)
EOF
    g.should have_error(Laser::UnassignedLHSError).on_line(3)
  end

  it 'should find dynamically-proven discarded RHS vals' do
    g = cfg <<-EOF
class TupleMisuse1
  def foo(x)
    a, b = bar(x)
  end
  def bar(x)
    [x, x, x]
  end
end
TupleMisuse1.new.foo(gets)
EOF
    g.should have_error(Laser::DiscardedRHSError).on_line(3)
  end

  it 'should find dynamically-proven unassigned LHS splats' do
    g = cfg <<-EOF
class TupleMisuse1
  def foo(x)
    a, *b, c = bar(x)
  end
  def bar(x)
    [x, x]
  end
end
TupleMisuse1.new.foo(gets)
EOF
    g.should have_error(Laser::UnassignedLHSError).on_line(3)
  end

  it 'should find dynamically-proven wasted RHS splat vals' do
    g = cfg <<-EOF
class TupleMisuse1
  def foo(x)
    a, b, c = x, x, *bar(x)
  end
  def bar(x)
    [x, x]
  end
end
TupleMisuse1.new.foo(gets)
EOF
    g.should have_error(Laser::DiscardedRHSError).on_line(3)
  end


  it 'should find dynamically-proven unassigned LHS splats with an RHS splat too' do
    g = cfg <<-EOF
class TupleMisuse1
  def foo(x)
    a, *b, c, d = x, *bar(x)
  end
  def bar(x)
    [x, x]
  end
end
TupleMisuse1.new.foo(gets)
EOF
    g.should have_error(Laser::UnassignedLHSError).on_line(3)
  end
end
