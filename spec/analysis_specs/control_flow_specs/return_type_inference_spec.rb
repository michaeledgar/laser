require_relative 'spec_helper'

describe 'CFG-based return type inference' do
  it 'should infer types based on specified overloads' do
    g = cfg <<-EOF
module RTI2
  def self.multiply(x, y)
    x * y
  end
end
EOF
    method = ClassRegistry['RTI2'].singleton_class.instance_method('multiply')
    method.return_type_for_types(
        Utilities.type_for(ClassRegistry['RTI2']), 
        [Types::FIXNUM, Types::FLOAT]).should equal_type Types::UnionType.new([Types::FLOAT])
    method.return_type_for_types(
        Utilities.type_for(ClassRegistry['RTI2']),
        [Types::FIXNUM, Types::FIXNUM]).should equal_type Types::UnionType.new([Types::FIXNUM, Types::BIGNUM])
  end

  it 'should infer type errors on methods with specified overloads' do
    g = cfg <<-EOF
module RTI3
  def self.sim3
    if gets.size > 2
      x = 'hi'
    else
      x = :hi
    end
    y = 15 * x
  end
end
EOF
   ClassRegistry['RTI3'].singleton_class.instance_method('sim3').
       return_type_for_types(
         Utilities.type_for(ClassRegistry['RTI3'])).should == nil
   g.should have_error(NoMatchingTypeSignature).on_line(8).with_message(/\*/)
  end

  it 'should infer the type resulting from a simple chain of standard-library methods' do
    g = cfg <<-EOF
module RTI4
  def self.bar
    x = gets
    qux(baz(x))
  end
  def self.baz(y)
    y.to_sym.size
  end
  def self.qux(z)
    z.zero?
  end
end
EOF
    ClassRegistry['RTI4'].singleton_class.instance_method('bar').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['RTI4'])).should equal_type Types::BOOLEAN
  end

  it 'should infer the type resulting from Class#new' do
    g = cfg <<-EOF
module RTI5
  class Foo
    def initialize(x, y)
      @x = x
      @y = y
    end
  end
  def self.make_a_foo(a, b)
    Foo.new(a, b)
  end
end
EOF
    result = Types::UnionType.new([Types::ClassType.new('RTI5::Foo', :invariant)])
    ClassRegistry['RTI5'].singleton_class.instance_method('make_a_foo').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['RTI5']),
          [Types::FIXNUM, Types::FLOAT]).should equal_type result
  end

  it 'should infer types based on SSA, when appropriate' do
    g = cfg <<-EOF
module RTI6
  def self.multiply
    if $$ > 10
      a = 'hello'
    else
      a = 20
    end
    a * 3
  end
end
EOF
    result = Types::UnionType.new([Types::FIXNUM, Types::BIGNUM, Types::STRING])
    ClassRegistry['RTI6'].singleton_class.instance_method('multiply').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['RTI6'])).should equal_type result
  end

  it 'should improve type inference due to SSA, when appropriate' do
    g = cfg <<-EOF
module RTI7
  def self.multiply
    if $$ > 10
      a = 'hello'
    else
      a = 20
    end
    b = a * 3
    a = 3.14
    a * 20
  end
end
EOF
    ClassRegistry['RTI7'].singleton_class.instance_method('multiply').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['RTI7'])).should equal_type Types::FLOAT
  end

  it 'should handle, via SSA, uninitialized variable types' do
    g = cfg <<-EOF
class RTI8
  def self.switch
    if $$ > 10
      a = 'hello'
    end
    b = a
  end
end
EOF
    ClassRegistry['RTI8'].singleton_class.instance_method('switch').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['RTI8'])).should equal_type(
            Types::UnionType.new([Types::STRING, Types::NILCLASS]))
  end
  
  it 'should warn against certain methods with improper return types' do
    g = cfg <<-EOF
class RTI8
  def to_s
    gets.strip!  # whoops, ! means nil sometimes
  end
end
EOF
    ClassRegistry['RTI8'].instance_method('to_s').
        return_type_for_types(
          ClassRegistry['RTI8'].as_type)  # force calculation
    ClassRegistry['RTI8'].instance_method('to_s').proc.ast_node.should(
        have_error(ImproperOverloadTypeError).with_message(/to_s/))
  end

  it 'should collect inferred types in global variables' do
    g = cfg <<-EOF
module RTI9
  def self.bar
    $sim9 = x = gets
    qux(baz(x))
  end
  def self.baz(y)
    $sim9 = y.to_sym.size
  end
  def self.qux(z)
    $sim9
  end
end
EOF
    # First, qux should give nil
    ClassRegistry['RTI9'].singleton_class.instance_method('qux').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['RTI9']), [Types::STRING]).should equal_type Types::NILCLASS
    expected_type = Types::UnionType.new(
        [Types::STRING, Types::FIXNUM, Types::BIGNUM, Types::NILCLASS])
    ClassRegistry['RTI9'].singleton_class.instance_method('bar').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['RTI9'])).should equal_type expected_type
    Scope::GlobalScope.lookup('$sim9').expr_type.should equal_type expected_type
    ClassRegistry['RTI9'].singleton_class.instance_method('qux').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['RTI9']), [Types::STRING]).should equal_type expected_type
  end
  
  it 'should collect inferred types in instance variables by class' do
    g = cfg <<-EOF
class TI1
  def set_foo(x)
    @foo = x
  end
  def get_foo
    @foo
  end
end
class TI2
  def set_foo(x)
    @foo = x
  end
  def get_foo
    @foo
  end
end
EOF
    ClassRegistry['TI1'].instance_method('get_foo').return_type_for_types(
        ClassRegistry['TI1'].as_type).should equal_type Types::NILCLASS
    ClassRegistry['TI1'].instance_method('set_foo').return_type_for_types(
        ClassRegistry['TI1'].as_type, [Types::STRING]).should equal_type Types::STRING
    ClassRegistry['TI1'].instance_method('get_foo').return_type_for_types(
        ClassRegistry['TI1'].as_type).should equal_type(
          Types::UnionType.new([Types::NILCLASS, Types::STRING]))
    ClassRegistry['TI1'].instance_method('set_foo').return_type_for_types(
        ClassRegistry['TI1'].as_type, [Types::FIXNUM]).should equal_type Types::FIXNUM
    ClassRegistry['TI1'].instance_method('get_foo').return_type_for_types(
        ClassRegistry['TI1'].as_type).should equal_type(
          Types::UnionType.new([Types::NILCLASS, Types::STRING, Types::FIXNUM]))
    
    ClassRegistry['TI2'].instance_method('get_foo').return_type_for_types(
        ClassRegistry['TI2'].as_type).should equal_type Types::NILCLASS
    ClassRegistry['TI2'].instance_method('set_foo').return_type_for_types(
        ClassRegistry['TI2'].as_type, [Types::FIXNUM]).should equal_type Types::FIXNUM
    ClassRegistry['TI2'].instance_method('get_foo').return_type_for_types(
        ClassRegistry['TI2'].as_type).should equal_type(
          Types::UnionType.new([Types::NILCLASS, Types::FIXNUM]))
  end
  
  it 'should extract argument types from rest arguments by index' do
    g = cfg <<-EOF
class RTI11
  def foo(*args)
    args[0]
  end
  def bar(*args)
    args[1]
  end
end
EOF
    ClassRegistry['RTI11'].instance_method('foo').return_type_for_types(
      ClassRegistry['RTI11'].as_type, [Types::FIXNUM, Types::PROC]).should equal_type Types::FIXNUM
    ClassRegistry['RTI11'].instance_method('bar').return_type_for_types(
      ClassRegistry['RTI11'].as_type, [Types::FIXNUM, Types::PROC]).should equal_type Types::PROC
  end
  
  it 'should extract argument types from rest arguments by range index' do
    g = cfg <<-EOF
class RTI12
  def foo(*args)
    args[0..1]
  end
  def bar(*args)
    args[1..3]
  end
  def baz(*args)
    args[-3..4]
  end
  def qux(*args)
    args[-4..4]
  end
end
EOF
    ClassRegistry['RTI12'].instance_method('foo').return_type_for_types(
      ClassRegistry['RTI12'].as_type, [Types::FIXNUM, Types::PROC, Types::TRUECLASS]).should equal_type(
        Types::TupleType.new([Types::FIXNUM, Types::PROC]))
    ClassRegistry['RTI12'].instance_method('bar').return_type_for_types(
      ClassRegistry['RTI12'].as_type, [Types::STRING, Types::FLOAT, Types::HASH]).should equal_type(
        Types::TupleType.new([Types::FLOAT, Types::HASH]))
    ClassRegistry['RTI12'].instance_method('baz').return_type_for_types(
      ClassRegistry['RTI12'].as_type, [Types::STRING, Types::FLOAT, Types::HASH]).should equal_type(
        Types::TupleType.new([Types::STRING, Types::FLOAT, Types::HASH]))
    ClassRegistry['RTI12'].instance_method('qux').return_type_for_types(
      ClassRegistry['RTI12'].as_type, [Types::STRING, Types::FLOAT, Types::HASH]).should equal_type(
        Types::NILCLASS)
  end
end
