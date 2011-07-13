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
    method = ClassRegistry['RI1'].instance_method('tap_10')
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
    method = ClassRegistry['RI2'].instance_method('raise_string')
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
    method = ClassRegistry['RI3'].instance_method('raise_class')
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
    method = ClassRegistry['RI4'].instance_method('raise_instance')
    method.raise_type_for_types(
        Utilities.type_for(ClassRegistry['RI4'])).should equal_type(
          Types::UnionType.new([Types::ClassType.new('ArgumentError', :invariant)]))
  end
end