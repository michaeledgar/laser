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
    ClassRegistry['Sim2'].instance_methods['foo'].should_not be_nil
  end
  
  it 'should simulate toplevel alias_method calls' do
    g = cfg <<-EOF
class Sim3
  def foo(x, y)
  end
  alias_method :bar, :foo
end
EOF
    ClassRegistry['Sim3'].instance_methods['foo'].should ==
        ClassRegistry['Sim3'].instance_methods['bar']
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
    old_foo = ClassRegistry['Sim4'].instance_methods['foo']
    new_foo = ClassRegistry['Sim4'].instance_methods['foo_with_fun']
    g2 = cfg %q{
class Sim4
  alias_method_chain :foo, :fun
end
}
    ClassRegistry['Sim4'].instance_methods['foo_without_fun'].should == old_foo
    ClassRegistry['Sim4'].instance_methods['foo'].should == new_foo
  end
end