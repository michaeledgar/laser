require_relative 'spec_helper'

describe ControlFlow::RaiseProperties do
  it 'should recognize simple methods that raise no exceptions due to constants' do
    g = cfg_method <<-EOF
def foo(x)
  y = 'hello' * 2
  p(y)
  y.singleton_class
end
EOF
    g.raise_frequency.should be Frequency::NEVER
  end

  it 'should recognize simple methods that unconditionally raise' do
    g = cfg_method <<-EOF
def foo(x)
  raise SomeError.new(x)
end
EOF
    g.raise_frequency.should be Frequency::ALWAYS
  end

  it 'should recognize raiseability via aliases' do
    g = cfg_method <<-EOF
def foo(x)
  fail SomeError.new(x)
end
EOF
    g.raise_frequency.should be Frequency::ALWAYS
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
    g.raise_frequency.should be Frequency::MAYBE
  end

  it 'should recognize when private methods are called' do
    g = cfg_method <<-EOF
def foo(x)
  String.alias_method(:bar, :<<)
end
EOF
    g.raise_frequency.should be Frequency::ALWAYS
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
    method.raise_frequency_for_types(
        Utilities.type_for(ClassRegistry['RInfer1']), 
        [Types::FIXNUM], 
        Types::NILCLASS).should == Frequency::NEVER
    method.raise_frequency_for_types(
        Utilities.type_for(ClassRegistry['RInfer1']),
        [Types::STRING],
        Types::NILCLASS).should == Frequency::ALWAYS
  end
  
  it 'should infer raises from #initialize when calling Class.new' do
    g = cfg <<-EOF
class RInfer2
  def initialize(x)
    raise TypeError.new("I don't like integers") if Integer === x
  end
end
def make_rinfer_2(x)
  RInfer2.new(x)
end
EOF
    method = ClassRegistry['Object'].instance_method('make_rinfer_2')
    # call make_rinfer_2 should raise for a fixnum
    method.raise_frequency_for_types(
        Utilities.type_for(ClassRegistry['String']),  # doesn't matter
        [Types::FIXNUM], 
        Types::NILCLASS).should == Frequency::ALWAYS
    method.raise_frequency_for_types(
        Utilities.type_for(ClassRegistry['String']),  # doesn't matter
        [ClassRegistry['Bignum'].as_type], 
        Types::NILCLASS).should == Frequency::ALWAYS
    method.raise_frequency_for_types(
        Utilities.type_for(ClassRegistry['String']),  # doesn't matter
        [Types::STRING], 
        Types::NILCLASS).should == Frequency::NEVER
  end
end