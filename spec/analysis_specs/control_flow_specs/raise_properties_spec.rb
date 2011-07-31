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
  if gets  # may raise
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
        Types::STRING,  # doesn't matter
        [Types::FIXNUM], 
        Types::NILCLASS).should == Frequency::ALWAYS
    method.raise_frequency_for_types(
        Types::STRING,  # doesn't matter
        [ClassRegistry['Bignum'].as_type], 
        Types::NILCLASS).should == Frequency::ALWAYS
    method.raise_frequency_for_types(
        Types::STRING,  # doesn't matter
        [Types::STRING], 
        Types::NILCLASS).should == Frequency::NEVER
  end

  it 'should infer a potential raises by argument type' do
    g = cfg <<-EOF
class RInfer3
  def initialize(x)
    try_to_foo(x) if x != 0
  end

  def try_to_foo(x)
    case x
    when Integer
      raise ArgumentError.new('no negative numbers') if x < 0
    when Float
      raise TypeError.new('no floats at all')
    else
      x.ljust(20)
    end
  end
end
def make_RInfer_3(x)
  RInfer3.new(x)
end
EOF
    method = ClassRegistry['Object'].instance_method('make_RInfer_3')
    # call make_rinfer_2 should raise for a fixnum
    method.raise_frequency_for_types(
        Types::STRING,  # doesn't matter
        [Types::FLOAT], 
        Types::NILCLASS).should == Frequency::MAYBE
    method.raise_frequency_for_types(
        Types::STRING,  # doesn't matter
        [ClassRegistry['Bignum'].as_type], 
        Types::NILCLASS).should == Frequency::MAYBE
    method.raise_frequency_for_types(
        Types::STRING,  # doesn't matter
        [Types::ARRAY], 
        Types::NILCLASS).should == Frequency::MAYBE   # not smart enough to prove != 0 yet
    method.raise_frequency_for_types(
        Types::STRING,  # doesn't matter
        [Types::STRING], 
        Types::NILCLASS).should == Frequency::NEVER
  end
  
  it 'can infer raises from calls to the annotated String class' do
    g = cfg <<-EOF
class RInfer4
  def silly(x)
    x.getbyte(x.size * 2)
  end
end
EOF
    method = ClassRegistry['RInfer4'].instance_method('silly')
    method.raise_frequency_for_types(
        Utilities.type_for(ClassRegistry['RInfer4']),
        [Types::STRING],
        Types::NILCLASS).should == Frequency::MAYBE
    method.raise_frequency_for_types(
        Utilities.type_for(ClassRegistry['RInfer4']),
        [Types::FIXNUM],
        Types::NILCLASS).should == Frequency::ALWAYS
  end

  it 'can infer a guaranteed NoMethodError from privacy violations' do
    g = cfg <<-EOF
class RInfer5
  def foo
  end
  private :foo

  def bar
    self.foo  # error!
  end
end
EOF
    method = ClassRegistry['RInfer5'].instance_method('bar')
    method.raise_frequency_for_types(
        Utilities.type_for(ClassRegistry['RInfer5'])).should == Frequency::ALWAYS
  end

  it 'can infer a potential lookup failure when a successful one exists' do
    g = cfg <<-EOF
class RInfer6
  def bar
    if gets.size > 0
      x = 'hello'
    else
      x = 5
    end
    x.intern  # error sometimes
  end
end
EOF
    method = ClassRegistry['RInfer6'].instance_method('bar')
    method.raise_frequency_for_types(
        Utilities.type_for(ClassRegistry['RInfer6'])).should == Frequency::MAYBE
  end

  it 'can infer an ArgumentError when invalid arities are given' do
    g = cfg <<-EOF
class RInfer7
  def foo(*args)
    bar(*args)
  end
  def bar(a, b=1, c=2, d)
    a
  end
end
EOF
    method = ClassRegistry['RInfer7'].instance_method('foo')
    method.raise_frequency_for_types(
        ClassRegistry['RInfer7'].as_type).should == Frequency::ALWAYS
    method.raise_frequency_for_types(
        ClassRegistry['RInfer7'].as_type,
        [Types::STRING]).should == Frequency::ALWAYS
    method.raise_frequency_for_types(
        ClassRegistry['RInfer7'].as_type,
        [Types::STRING, Types::FIXNUM]).should == Frequency::NEVER
    method.raise_frequency_for_types(
        ClassRegistry['RInfer7'].as_type,
        [Types::STRING, Types::FIXNUM,
         Types::BIGNUM]).should == Frequency::NEVER
    method.raise_frequency_for_types(
        ClassRegistry['RInfer7'].as_type,
        [Types::STRING, Types::FIXNUM,
         Types::BIGNUM, Types::ARRAY]).should == Frequency::NEVER
    method.raise_frequency_for_types(
        ClassRegistry['RInfer7'].as_type,
        [Types::STRING, Types::FIXNUM, Types::BIGNUM,
         Types::ARRAY, Types::HASH]).should == Frequency::ALWAYS
  end

  it 'can infer guaranteed errors when super provides incorrect arities' do
    g = cfg <<-EOF
class RInfer8
  def foo(a, b=1, c=2, d)
    a
  end
end
class RInfer8B < RInfer8
  def foo(*args)
    super(*args)
  end
end
EOF
    method = ClassRegistry['RInfer8B'].instance_method('foo')
    method.raise_frequency_for_types(
        ClassRegistry['RInfer8B'].as_type).should == Frequency::ALWAYS
    method.raise_frequency_for_types(
        ClassRegistry['RInfer8B'].as_type,
        [Types::STRING]).should == Frequency::ALWAYS
    method.raise_frequency_for_types(
        ClassRegistry['RInfer8B'].as_type,
        [Types::STRING, Types::FIXNUM]).should == Frequency::NEVER
    method.raise_frequency_for_types(
        ClassRegistry['RInfer8B'].as_type,
        [Types::STRING, Types::FIXNUM,
         Types::BIGNUM]).should == Frequency::NEVER
    method.raise_frequency_for_types(
        ClassRegistry['RInfer8B'].as_type,
        [Types::STRING, Types::FIXNUM,
         Types::BIGNUM, Types::ARRAY]).should == Frequency::NEVER
    method.raise_frequency_for_types(
        ClassRegistry['RInfer8B'].as_type,
        [Types::STRING, Types::FIXNUM, Types::BIGNUM,
         Types::ARRAY, Types::HASH]).should == Frequency::ALWAYS
  end

  it 'can infer guaranteed errors when zsuper provides incorrect arities' do
    g = cfg <<-EOF
class RInfer9
  def foo(a, b=1, c=2, d)
    a
  end
end
class RInfer9B < RInfer9
  def foo(*args)
    super
  end
end
EOF
    method = ClassRegistry['RInfer9B'].instance_method('foo')
    method.raise_frequency_for_types(
        ClassRegistry['RInfer9B'].as_type).should == Frequency::ALWAYS
    method.raise_frequency_for_types(
        ClassRegistry['RInfer9B'].as_type,
        [Types::STRING]).should == Frequency::ALWAYS
    method.raise_frequency_for_types(
        ClassRegistry['RInfer9B'].as_type,
        [Types::STRING, Types::FIXNUM]).should == Frequency::NEVER
    method.raise_frequency_for_types(
        ClassRegistry['RInfer9B'].as_type,
        [Types::STRING, Types::FIXNUM,
         Types::BIGNUM]).should == Frequency::NEVER
    method.raise_frequency_for_types(
        ClassRegistry['RInfer9B'].as_type,
        [Types::STRING, Types::FIXNUM,
         Types::BIGNUM, Types::ARRAY]).should == Frequency::NEVER
    method.raise_frequency_for_types(
        ClassRegistry['RInfer9B'].as_type,
        [Types::STRING, Types::FIXNUM, Types::BIGNUM,
         Types::ARRAY, Types::HASH]).should == Frequency::ALWAYS
  end
end
    