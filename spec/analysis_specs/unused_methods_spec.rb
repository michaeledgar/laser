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
end