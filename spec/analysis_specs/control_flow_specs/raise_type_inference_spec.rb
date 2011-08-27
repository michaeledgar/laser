require_relative 'spec_helper'

describe 'CFG-based raise type inference' do
  it 'should infer types based on specified overloads' do
    g = cfg <<-EOF
class RI1
  def tap_10
    yield 10
    10
  end
end
EOF
    method = ClassRegistry['RI1'].instance_method(:tap_10)
    method.raise_type_for_types(
        Utilities.type_for(ClassRegistry['RI1'])).should equal_type(
          Types::UnionType.new([Types::ClassType.new('LocalJumpError', :invariant)]))
  end
  
  it 'should infer types based on raising a string' do
    g = cfg <<-EOF
class RI2
  def raise_string
    raise 'foo'
  end
end
EOF
    method = ClassRegistry['RI2'].instance_method(:raise_string)
    method.raise_type_for_types(
        Utilities.type_for(ClassRegistry['RI2'])).should equal_type(
          Types::UnionType.new([Types::ClassType.new('RuntimeError', :invariant)]))
  end

  it 'should infer types based on raising an Exception class' do
    g = cfg <<-EOF
class RI3
  def raise_class
    raise TypeError
  end
end
EOF
    method = ClassRegistry['RI3'].instance_method(:raise_class)
    method.raise_type_for_types(
        Utilities.type_for(ClassRegistry['RI3'])).should equal_type(
          Types::UnionType.new([Types::ClassType.new('TypeError', :invariant)]))
  end

  it 'should infer types based on raising an Exception instance' do
    g = cfg <<-EOF
class RI4
  def raise_instance
    raise ArgumentError.new('foo')
  end
end
EOF
    method = ClassRegistry['RI4'].instance_method(:raise_instance)
    method.raise_type_for_types(
        Utilities.type_for(ClassRegistry['RI4'])).should equal_type(
          Types::UnionType.new([Types::ClassType.new('ArgumentError', :invariant)]))
  end
  
  it 'should infer raises from #initialize when calling Class.new' do
    g = cfg <<-EOF
class RTInfer2
  def initialize(x)
    raise TypeError.new("I don't like integers") if Integer === x
  end
end
def make_rtinfer_2(x)
  RTInfer2.new(x)
end
EOF
    method = ClassRegistry['Object'].instance_method(:make_rtinfer_2)
    # call make_rinfer_2 should raise for a fixnum
    method.raise_type_for_types(
        Types::STRING,  # doesn't matter
        [Types::FIXNUM], 
        Types::NILCLASS).should equal_type(ClassRegistry['TypeError'].as_type)
    method.raise_type_for_types(
        Types::STRING,  # doesn't matter
        [ClassRegistry['Bignum'].as_type], 
        Types::NILCLASS).should equal_type(ClassRegistry['TypeError'].as_type)
    method.raise_type_for_types(
        Types::STRING,  # doesn't matter
        [Types::STRING], 
        Types::NILCLASS).should equal_type(Types::EMPTY)
  end
  
  it 'should infer a potential raises by argument type' do
    g = cfg <<-EOF
class RTInfer3
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
def make_rtinfer_3(x)
  RTInfer3.new(x)
end
EOF
    method = ClassRegistry['Object'].instance_method(:make_rtinfer_3)
    # call make_rinfer_2 should raise for a fixnum
    method.raise_type_for_types(
        Types::STRING,  # doesn't matter
        [Types::FLOAT], 
        Types::NILCLASS).should equal_type(ClassRegistry['TypeError'].as_type)
    method.raise_type_for_types(
        Types::STRING,  # doesn't matter
        [ClassRegistry['Bignum'].as_type], 
        Types::NILCLASS).should equal_type(ClassRegistry['ArgumentError'].as_type)
    method.raise_type_for_types(
        Types::STRING,  # doesn't matter
        [Types::ARRAY], 
        Types::NILCLASS).should equal_type(ClassRegistry['NoMethodError'].as_type)
    method.raise_type_for_types(
        Types::STRING,  # doesn't matter
        [Types::STRING], 
        Types::NILCLASS).should equal_type(Types::EMPTY)
  end
  
  it 'can infer raises from calls to the annotated String class' do
    g = cfg <<-EOF
class RTInfer4
  def silly(x)
    x.getbyte(x.size * 2)
  end
end
EOF
    method = ClassRegistry['RTInfer4'].instance_method(:silly)
    method.raise_type_for_types(
        Utilities.type_for(ClassRegistry['RTInfer4']),
        [Types::STRING],
        Types::NILCLASS).should equal_type(ClassRegistry['IndexError'].as_type |
                                           ClassRegistry['TypeError'].as_type)
    method.raise_type_for_types(
        Utilities.type_for(ClassRegistry['RTInfer4']),
        [Types::FIXNUM],
        Types::NILCLASS).should equal_type(ClassRegistry['NoMethodError'].as_type)
  end
  
  it 'can infer a guaranteed NoMethodError from privacy violations' do
    g = cfg <<-EOF
class RTInfer5
  def foo
  end
  private :foo
  
  def bar
    self.foo  # error!
  end
end
EOF
    method = ClassRegistry['RTInfer5'].instance_method(:bar)
    method.raise_type_for_types(
        Utilities.type_for(ClassRegistry['RTInfer5'])).should(
          equal_type(ClassRegistry['NoMethodError'].as_type))
  end
  
  it 'can infer a potential lookup failure when a successful one exists' do
    g = cfg <<-EOF
class RTInfer6
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
    method = ClassRegistry['RTInfer6'].instance_method(:bar)
    method.raise_type_for_types(
        Utilities.type_for(ClassRegistry['RTInfer6'])).should(
          equal_type(ClassRegistry['NoMethodError'].as_type))
  end
  
  it 'can infer an ArgumentError when invalid arities are given' do
    g = cfg <<-EOF
class RTInfer7
  def foo(*args)
    bar(*args)
  end
  def bar(a, b=1, c=2, d)
    a
  end
end
EOF
    method = ClassRegistry['RTInfer7'].instance_method(:foo)
    method.raise_type_for_types(
        ClassRegistry['RTInfer7'].as_type).should(
          equal_type(ClassRegistry['ArgumentError'].as_type))
    method.raise_type_for_types(
        ClassRegistry['RTInfer7'].as_type,
        [Types::STRING]).should(
          equal_type(ClassRegistry['ArgumentError'].as_type))
    method.raise_type_for_types(
        ClassRegistry['RTInfer7'].as_type,
        [Types::STRING, Types::FIXNUM]).should(
          equal_type(Types::EMPTY))
    method.raise_type_for_types(
        ClassRegistry['RTInfer7'].as_type,
        [Types::STRING, Types::FIXNUM, Types::BIGNUM]).should(
          equal_type(Types::EMPTY))
    method.raise_type_for_types(
        ClassRegistry['RTInfer7'].as_type,
        [Types::STRING, Types::FIXNUM, Types::BIGNUM, Types::ARRAY]).should(
          equal_type(Types::EMPTY))
    method.raise_type_for_types(
        ClassRegistry['RTInfer7'].as_type,
        [Types::STRING, Types::FIXNUM, Types::BIGNUM, Types::ARRAY, Types::HASH]).should(
          equal_type(ClassRegistry['ArgumentError'].as_type))
  end

  it 'can infer an ArgumentError when super provides incorrect arities' do
    g = cfg <<-EOF
class RTInfer8
  def foo(a, b=1, c=2, d)
    a
  end
end
class RTInfer8B < RTInfer8
  def foo(*args)
    super(*args)
  end
end
EOF
    method = ClassRegistry['RTInfer8B'].instance_method(:foo)
    method.raise_type_for_types(
        ClassRegistry['RTInfer8B'].as_type).should(
          equal_type(ClassRegistry['ArgumentError'].as_type))
    method.raise_type_for_types(
        ClassRegistry['RTInfer8B'].as_type,
        [Types::STRING]).should(
          equal_type(ClassRegistry['ArgumentError'].as_type))
    method.raise_type_for_types(
        ClassRegistry['RTInfer8B'].as_type,
        [Types::STRING, Types::FIXNUM]).should(
          equal_type(Types::EMPTY))
    method.raise_type_for_types(
        ClassRegistry['RTInfer8B'].as_type,
        [Types::STRING, Types::FIXNUM, Types::BIGNUM]).should(
          equal_type(Types::EMPTY))
    method.raise_type_for_types(
        ClassRegistry['RTInfer8B'].as_type,
        [Types::STRING, Types::FIXNUM, Types::BIGNUM, Types::ARRAY]).should(
          equal_type(Types::EMPTY))
    method.raise_type_for_types(
        ClassRegistry['RTInfer8B'].as_type,
        [Types::STRING, Types::FIXNUM, Types::BIGNUM, Types::ARRAY, Types::HASH]).should(
          equal_type(ClassRegistry['ArgumentError'].as_type))
  end

  it 'can infer an ArgumentError when zsuper provides incorrect arities' do
    g = cfg <<-EOF
class RTInfer9
  def foo(a, b=1, c=2, d)
    a
  end
end
class RTInfer9B < RTInfer9
  def foo(*args)
    super
  end
end
EOF
    method = ClassRegistry['RTInfer9B'].instance_method(:foo)
    method.raise_type_for_types(
        ClassRegistry['RTInfer9B'].as_type).should(
          equal_type(ClassRegistry['ArgumentError'].as_type))
    method.raise_type_for_types(
        ClassRegistry['RTInfer9B'].as_type,
        [Types::STRING]).should(
          equal_type(ClassRegistry['ArgumentError'].as_type))
    method.raise_type_for_types(
        ClassRegistry['RTInfer9B'].as_type,
        [Types::STRING, Types::FIXNUM]).should(
          equal_type(Types::EMPTY))
    method.raise_type_for_types(
        ClassRegistry['RTInfer9B'].as_type,
        [Types::STRING, Types::FIXNUM, Types::BIGNUM]).should(
          equal_type(Types::EMPTY))
    method.raise_type_for_types(
        ClassRegistry['RTInfer9B'].as_type,
        [Types::STRING, Types::FIXNUM, Types::BIGNUM, Types::ARRAY]).should(
          equal_type(Types::EMPTY))
    method.raise_type_for_types(
        ClassRegistry['RTInfer9B'].as_type,
        [Types::STRING, Types::FIXNUM, Types::BIGNUM, Types::ARRAY, Types::HASH]).should(
          equal_type(ClassRegistry['ArgumentError'].as_type))
  end
end
