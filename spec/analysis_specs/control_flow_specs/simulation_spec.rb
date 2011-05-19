require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ControlFlow::Simulation do
  it 'should create classes during toplevel simulation' do
    g = cfg <<-EOF
class Sim1 < Hash
end
EOF
    ClassRegistry['Sim1'].should_not be nil
    ClassRegistry['Sim1'].superclass.should == ClassRegistry['Hash']
  end
  
  it 'should create methods during toplevel simulation' do
    g = cfg <<-EOF
class Sim2
  def foo(x, y)
  end
end
EOF
    ClassRegistry['Sim2'].instance_method('foo').should_not be_nil
  end
  
  it 'should simulate toplevel alias_method calls' do
    g = cfg <<-EOF
class Sim3
  def foo(x, y)
  end
  alias_method :bar, :foo
end
EOF
    ClassRegistry['Sim3'].instance_method('foo').should ==
        ClassRegistry['Sim3'].instance_method('bar')
  end

  it 'should simulate toplevel general calls' do
    g = cfg %q{
class Sim4
  class << self
    def alias_method_chain(name, suffix)
      alias_method "#{name}_without_#{suffix}", name
      alias_method name, "#{name}_with_#{suffix}"
    end
  end

  def foo(x, y)
  end
  def foo_with_fun(x, y)
  end
end
}
    old_foo = ClassRegistry['Sim4'].instance_method('foo')
    new_foo = ClassRegistry['Sim4'].instance_method('foo_with_fun')
    g2 = cfg %q{
class Sim4
  alias_method_chain :foo, :fun
end
}
    ClassRegistry['Sim4'].instance_method('foo_without_fun').should == old_foo
    ClassRegistry['Sim4'].instance_method('foo').should == new_foo
  end
  
  it 'should simulate ruby-level attr_{reader,writer,accessor} calls' do
    g = cfg %q{
class Sim5
  attr_reader :foo, :bar
  attr_writer :baz
  attr_accessor :qux, :pie
end
}

    %w(foo bar qux pie).each do |name|
      method = ClassRegistry['Sim5'].instance_method(name)
      method.should be_a(LaserMethod)
      method.arity.should == Arity.new(0..0)
    end

    %w(baz= qux= pie=).each do |name|
      method = ClassRegistry['Sim5'].instance_method(name)
      method.should be_a(LaserMethod)
      method.arity.should == Arity.new(1..1)
    end
  end

  it 'should simulate blocks being called by builtins' do
    g = cfg %q{
input = (1..10).to_a
output = input.map do |x|
  x ** x
end
}

    expected = (1..10).map { |x| x ** x }
    g.var_named('output').value.should == expected
  end
  
  it 'should simulate #define_method with a block' do
    g = cfg %q{
class Sim6
  [1, 2].each do |multiplicand|
    define_method("times_#{multiplicand}") { |x| x * multiplicand }
  end
end
}
    method = ClassRegistry['Sim6'].instance_method('times_1')
    method.should be_a(LaserMethod)
    method.arity.should == Arity.new(1..1)
    method = ClassRegistry['Sim6'].instance_method('times_1')
    method.should be_a(LaserMethod)
    method.arity.should == Arity.new(1..1)
  end
end
