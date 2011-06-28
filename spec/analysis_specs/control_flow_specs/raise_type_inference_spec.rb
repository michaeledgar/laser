require_relative 'spec_helper'

describe 'CFG-based raise type inference' do
  it 'should infer types based on specified overloads' do
    g = cfg <<-EOF
module RI1
  def tap_10
    yield 10
    10
  end
end
EOF
    method = ClassRegistry['RI1'].instance_method('tap_10')
    method.raise_type_for_types(
        Utilities.type_for(ClassRegistry['RI1'])).should ==
          Types::UnionType.new([Types::ClassType.new('LocalJumpError', :invariant)])
  end
end