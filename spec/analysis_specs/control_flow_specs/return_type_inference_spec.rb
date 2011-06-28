require_relative 'spec_helper'

describe 'CFG-based return type inference' do
  it 'should infer types based on specified overloads' do
    g = cfg <<-EOF
module CPSim2
  def self.multiply(x, y)
    x * y
  end
end
EOF
    method = ClassRegistry['CPSim2'].singleton_class.instance_method('multiply')
    method.return_type_for_types(
        Utilities.type_for(ClassRegistry['CPSim2']), 
        [Types::FIXNUM, Types::FLOAT]).should == Types::UnionType.new([Types::FLOAT])
    method.return_type_for_types(
        Utilities.type_for(ClassRegistry['CPSim2']),
        [Types::FIXNUM, Types::FIXNUM]).should == Types::UnionType.new([Types::FIXNUM, Types::BIGNUM])
  end

  it 'should infer type errors on methods with specified overloads' do
    g = cfg <<-EOF
module CPSim3
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
   ClassRegistry['CPSim3'].singleton_class.instance_method('sim3').
       return_type_for_types(
         Utilities.type_for(ClassRegistry['CPSim3'])).should == nil
   g.should have_error(NoMatchingTypeSignature).on_line(8).with_message(/\*/)
  end

  it 'should infer the type resulting from a simple chain of standard-library methods' do
    g = cfg <<-EOF
module CPSim4
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
    ClassRegistry['CPSim4'].singleton_class.instance_method('bar').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['CPSim4'])).should == Types::BOOLEAN
  end

  it 'should infer the type resulting from Class#new' do
    g = cfg <<-EOF
module CPSim5
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
    result = Types::UnionType.new([Types::ClassType.new('CPSim5::Foo', :invariant)])
    ClassRegistry['CPSim5'].singleton_class.instance_method('make_a_foo').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['CPSim5']),
          [Types::FIXNUM, Types::FLOAT]).should == result
  end

  it 'should infer types based on SSA, when appropriate' do
    g = cfg <<-EOF
module CPSim6
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
    ClassRegistry['CPSim6'].singleton_class.instance_method('multiply').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['CPSim6'])).should == result
  end

  it 'should improve type inference due to SSA, when appropriate' do
    g = cfg <<-EOF
module CPSim7
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
    ClassRegistry['CPSim7'].singleton_class.instance_method('multiply').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['CPSim7'])).should == Types::FLOAT
  end

  it 'should handle, via SSA, uninitialized variable types' do
    g = cfg <<-EOF
class CPSim8
  def self.switch
    if $$ > 10
      a = 'hello'
    end
    b = a
  end
end
EOF
    ClassRegistry['CPSim8'].singleton_class.instance_method('switch').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['CPSim8'])).should ==
            Types::UnionType.new([Types::STRING, Types::NILCLASS])
  end
  
  it 'should warn against certain methods with improper return types' do
    g = cfg <<-EOF
class CPSim8
  def to_s
    gets.strip!  # whoops, ! means nil sometimes
  end
end
EOF
    ClassRegistry['CPSim8'].instance_method('to_s').
        return_type_for_types(
          ClassRegistry['CPSim8'].as_type)  # force calculation
    ClassRegistry['CPSim8'].instance_method('to_s').proc.ast_node.should(
        have_error(ImproperOverloadTypeError).with_message(/to_s/))
  end

  it 'should collect inferred types in global variables' do
    g = cfg <<-EOF
module CPSim9
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
    ClassRegistry['CPSim9'].singleton_class.instance_method('qux').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['CPSim9']), [Types::STRING]).should == Types::NILCLASS
    expected_type = Types::UnionType.new(
        [Types::STRING, Types::FIXNUM, Types::BIGNUM, Types::NILCLASS])
    ClassRegistry['CPSim9'].singleton_class.instance_method('bar').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['CPSim9'])).should == expected_type
    Scope::GlobalScope.lookup('$sim9').expr_type.should == expected_type
    ClassRegistry['CPSim9'].singleton_class.instance_method('qux').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['CPSim9']), [Types::STRING]).should == expected_type
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
        ClassRegistry['TI1'].as_type).should == Types::NILCLASS
    ClassRegistry['TI1'].instance_method('set_foo').return_type_for_types(
        ClassRegistry['TI1'].as_type, [Types::STRING]).should ==
          Types::STRING
    ClassRegistry['TI1'].instance_method('get_foo').return_type_for_types(
        ClassRegistry['TI1'].as_type).should ==
          Types::UnionType.new([Types::NILCLASS, Types::STRING])
    ClassRegistry['TI1'].instance_method('set_foo').return_type_for_types(
        ClassRegistry['TI1'].as_type, [Types::FIXNUM]).should ==
         Types::FIXNUM
    ClassRegistry['TI1'].instance_method('get_foo').return_type_for_types(
        ClassRegistry['TI1'].as_type).should ==
          Types::UnionType.new([Types::NILCLASS, Types::STRING, Types::FIXNUM])
    
    ClassRegistry['TI2'].instance_method('get_foo').return_type_for_types(
        ClassRegistry['TI2'].as_type).should == Types::NILCLASS
    ClassRegistry['TI2'].instance_method('set_foo').return_type_for_types(
        ClassRegistry['TI2'].as_type, [Types::FIXNUM]).should ==
          Types::FIXNUM
    ClassRegistry['TI2'].instance_method('get_foo').return_type_for_types(
        ClassRegistry['TI2'].as_type).should ==
          Types::UnionType.new([Types::NILCLASS, Types::FIXNUM])
  end
end
