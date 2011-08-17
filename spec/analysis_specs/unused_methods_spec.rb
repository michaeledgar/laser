require_relative 'spec_helper'

describe UnusedMethodDetection do
  before(:all) do
    Laser::Analysis::LaserMethod.default_dispatched = false
  end

  # We don't want unused methods flowing into the next test, so
  # mark each unused method as used afterward.
  after(:each) do
    @methods.each do |method|
      method.been_used!
    end
  end

  after(:all) do
    Laser::Analysis::LaserMethod.default_dispatched = true
  end

  it 'can discover a simple case of an unused method' do
    cfg <<-EOF
class UnusedMethod1
  def foo(x)
    bar(x)
  end
  def bar(x, y=x)
  end
  def baz
  end
end
UnusedMethod1.new.foo(gets)
EOF
    @methods = UnusedMethodDetection.unused_methods
    @methods.should == [ClassRegistry['UnusedMethod1'].instance_method(:baz)]
  end

  it 'discovers method use through super' do
cfg <<-EOF
class UnusedMethod2
  def foo(x)
    x
  end
  def bar(x, y=x)
  end
end
class UnusedMethod3 < UnusedMethod2
  def foo(x)
    bar(x)
  end
  def bar(x, y=x)
    super
    y
  end
  def baz
  end
end
UnusedMethod3.new.foo(gets)
EOF
    @methods = UnusedMethodDetection.unused_methods

    Set.new(@methods).should ==
      Set[ClassRegistry['UnusedMethod2'].instance_method(:foo),
          ClassRegistry['UnusedMethod3'].instance_method(:baz)]
  end

  it 'does not mark failed dispatches as used' do
    cfg <<-EOF
class UnusedMethod4
  def foo(x)
  end
  def bar(x, y=x)
  end
  def baz(a, b, *rest)
    bar(*rest)
  end
end
inst = UnusedMethod4.new
inst.foo(gets)  # marks foo as used
inst.baz(gets, gets, gets, gets, gets)  # marks baz, but not bar
EOF
    @methods = UnusedMethodDetection.unused_methods

    Set.new(@methods).should ==
      Set[ClassRegistry['UnusedMethod4'].instance_method(:bar)]
  end

  it 'works with send on constants, respecting arity' do
    cfg <<-EOF
class UnusedMethod5
  def zero
  end
  def one_or_two(a, b=1)
  end
  def two(a, b)
  end
  def three(a, b, c)
  end
  def any(*rest)
  end
end
choice = [:zero, :one_or_two, :two, :three, :any][gets.to_i]
UnusedMethod5.new.send(choice, gets, gets)
EOF
    @methods = UnusedMethodDetection.unused_methods

    Set.new(@methods).should ==
      Set[ClassRegistry['UnusedMethod5'].instance_method(:zero),
          ClassRegistry['UnusedMethod5'].instance_method(:three)]
  end

  it 'works with public_send on constants, respecting privacy' do
    cfg <<-EOF
class UnusedMethod6
  def public_one_or_two(a, b=1)
  end
  def public_two(a, b)
  end
 private
  def private_two(a, b)
  end
 protected
  def protected_two(a, b)
  end
end
choice = [:public_one_or_two, :public_two, 
          :private_two, :protected_two][gets.to_i]
UnusedMethod6.new.public_send(choice, gets, gets)
EOF
    @methods = UnusedMethodDetection.unused_methods

    Set.new(@methods).should ==
      Set[ClassRegistry['UnusedMethod6'].instance_method(:private_two),
          ClassRegistry['UnusedMethod6'].instance_method(:protected_two)]
  end
end