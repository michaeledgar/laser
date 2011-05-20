require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'CFG-based type inference' do
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
        [Types::FIXNUM, Types::FLOAT], 
        Types::NILCLASS).should == Types::UnionType.new([Types::FLOAT])
    method.return_type_for_types(
        Utilities.type_for(ClassRegistry['CPSim2']),
        [Types::FIXNUM, Types::FIXNUM],
        Types::NILCLASS).should == Types::UnionType.new([Types::FIXNUM, Types::BIGNUM])
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
         Utilities.type_for(ClassRegistry['CPSim3']), [], Types::NILCLASS).should == nil
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
          Utilities.type_for(ClassRegistry['CPSim4']), [], Types::NILCLASS).should == Types::BOOLEAN
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
          [Types::FIXNUM, Types::FLOAT],
          Types::NILCLASS).should == result
  end

  it 'should infer types based on SSA, when appropriate' do
    g = cfg <<-EOF
module CPSim6
  def self.multiply
    if $foo > 10
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
          Utilities.type_for(ClassRegistry['CPSim6']), [], Types::NILCLASS).should == result
  end

  it 'should improve type inference due to SSA, when appropriate' do
    g = cfg <<-EOF
module CPSim7
  def self.multiply
    if $foo > 10
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
          Utilities.type_for(ClassRegistry['CPSim7']), [], Types::NILCLASS).should == Types::FLOAT
  end

  it 'should handle, via SSA, uninitialized variable types' do
    g = cfg <<-EOF
module CPSim8
  def self.switch
    if $foo > 10
      a = 'hello'
    end
    b = a
  end
end
EOF
    ClassRegistry['CPSim8'].singleton_class.instance_method('switch').
        return_type_for_types(
          Utilities.type_for(ClassRegistry['CPSim8']), [], Types::NILCLASS).should ==
            Types::UnionType.new([Types::STRING, Types::NILCLASS])
  end
end