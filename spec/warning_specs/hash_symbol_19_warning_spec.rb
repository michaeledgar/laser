require_relative 'spec_helper'

describe HashSymbol19Warning do
  it 'is a file-based warning' do
    HashSymbol19Warning.new('(stdin)', 'hello').should be_a(FileWarning)
  end

  it 'matches against a 1.8-style hash' do
    HashSymbol19Warning.should_not warn('x = { :foo => bar }')
  end
  
  it 'does not match against a 1.9-style hash' do
    HashSymbol19Warning.should warn('x = { foo: bar }')
  end
  
  it 'matches against a multiline 1.8-style hash' do
    HashSymbol19Warning.should_not warn('x = { :foo =>
bar }')
  end
  
  it 'does not match against a multiline 1.9-style hash' do
    HashSymbol19Warning.should warn('x = { foo:
bar }')
  end

  describe '#fix' do
    it 'fixes a simple 1.8-style single-keyed hash to 1.9-style hash keys' do
      input = <<-EOF
x = { foo: bar }
EOF
      output = <<-EOF
x = { :foo => bar }
EOF
      HashSymbol19Warning.new('(stdin)', input).match?(input).first.fix.should == output
    end

    it 'fixes many 1.8-style hash keys into 1.9-style hash keys' do
      input = %q{
with_jumps_redirected(break: ensure_body[1], redo: ensure_body[1], next: ensure_body[1],
                      return: ensure_body[1], rescue: ensure_body[1],
                      yield_fail: ensure_body[1]) do
  rescue_target, yield_fail_target =
      build_rescue_target(node, result, rescue_body, ensure_block,
                          current_rescue, current_yield_fail)
  walk_body_with_rescue_target(result, body, body_block, rescue_target, yield_fail_target)
end
}
     output = %q{
with_jumps_redirected(:break => ensure_body[1], :redo => ensure_body[1], :next => ensure_body[1],
                      :return => ensure_body[1], :rescue => ensure_body[1],
                      :yield_fail => ensure_body[1]) do
  rescue_target, yield_fail_target =
      build_rescue_target(node, result, rescue_body, ensure_block,
                          current_rescue, current_yield_fail)
  walk_body_with_rescue_target(result, body, body_block, rescue_target, yield_fail_target)
end
}
      HashSymbol19Warning.new('(stdin)', input).match?(input).inject(input) do |input, warning|
        warning.fix(input)
      end.should == output
    end
  end
end