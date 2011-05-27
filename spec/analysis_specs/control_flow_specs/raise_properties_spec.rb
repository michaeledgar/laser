require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ControlFlow::RaiseProperties do
  it 'should recognize simple methods that raise no exceptions due to constants' do
    g = cfg_method <<-EOF
def foo(x)
  y = 'hello' * 2
  p(y)
  y.singleton_class
end
EOF
    g.raise_type.should be Frequency::NEVER
  end

  it 'should recognize simple methods that unconditionally raise' do
    g = cfg_method <<-EOF
def foo(x)
  raise SomeError.new(x)
end
EOF
    g.raise_type.should be Frequency::ALWAYS
  end

  it 'should recognize raiseability via aliases' do
    g = cfg_method <<-EOF
def foo(x)
  fail SomeError.new(x)
end
EOF
    g.raise_type.should be Frequency::ALWAYS
  end

  it 'should recognize simple methods that might raise' do
    g = cfg_method <<-EOF
def foo(x)
  if x > 2  # may raise
    'hi'
  else
    'there'
  end
end
EOF
    g.raise_type.should be Frequency::MAYBE
  end

  it 'should recognize when private methods are called' do
    g = cfg_method <<-EOF
def foo(x)
  String.alias_method(:bar, :<<)
end
EOF
    g.raise_type.should be Frequency::ALWAYS
  end
  
  it 'should use types to improve raising inference on user code' do
    g = cfg <<-EOF
module RInfer1
  def self.multiply(x)
    check_and_mult(x)
  end
  
  def self.check_and_mult(y)
    if String === y
      raise 'no strings!'
    end
    p(y)
  end
end
EOF
    method = ClassRegistry['RInfer1'].singleton_class.instance_method('multiply')
    method.raise_type_for_types(
        Utilities.type_for(ClassRegistry['RInfer1']), 
        [Types::FIXNUM], 
        Types::NILCLASS).should == Frequency::NEVER
    method.raise_type_for_types(
        Utilities.type_for(ClassRegistry['RInfer1']),
        [Types::STRING],
        Types::NILCLASS).should == Frequency::ALWAYS
  end
end