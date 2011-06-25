require_relative 'spec_helper'

describe OperatorSpacing do
  it 'is a line-based warning' do
    OperatorSpacing.new('(stdin)', 'hello').should be_a(LineWarning)
  end

  it "doesn't match block declarations" do
    OperatorSpacing.should_not warn('[1, 2].each { |x| p x }')
    OperatorSpacing.should_not warn('[1, 2].each {| y | p x }')
    OperatorSpacing.should_not warn("[1, 2].each do |x|\n p x\nend")
    OperatorSpacing.should_not warn("[1, 2].each do|x|\n p x\nend")
  end

  it "doesn't match in a comment" do
    OperatorSpacing.should_not warn('hello # a+b')
  end

  it "doesn't match a <<- heredoc" do
    OperatorSpacing.should_not warn('@original = <<-EOF')
  end

  it "doesn't match a << heredoc" do
    OperatorSpacing.should_not warn('@original = <<EOF')
  end

  it "doesn't match adjacent negative numbers" do
    OperatorSpacing.should_not warn('  exit(-1)')
  end

  it "doesn't match *args in block parameters" do
    OperatorSpacing.should_not warn('list.each do |*args|')
    OperatorSpacing.should_not warn('list.each { |*args| }')
  end

  it "doesn't match splat arguments" do
    OperatorSpacing.should_not warn('x.call(*args)')
    OperatorSpacing.should_not warn('x.call(a, *args)')
    OperatorSpacing.should_not warn('x.call(*args, b)')
    OperatorSpacing.should_not warn('x.call(a, *args, b)')
  end

  it "does match multiplication in an argument list" do
    OperatorSpacing.should warn('x.call(a *b)')
    OperatorSpacing.should warn('x.call(x, a *b)')
    OperatorSpacing.should warn('x.call(a *b, z)')
  end

  it "doesn't match block arguments" do
    OperatorSpacing.should_not warn('x.call(&b)')
    OperatorSpacing.should_not warn('x.call(a, &b)')
    OperatorSpacing.should_not warn('x.call(&b, b)')
    OperatorSpacing.should_not warn('x.call(a, &b, b)')
    OperatorSpacing.should_not warn('@peek = wrapped_stream.move_forward_until(&@filter) or return true')
    OperatorSpacing.should_not warn('wrapped_stream.move_forward_until(&@filter)')
    OperatorSpacing.should_not warn('wrapped_stream.move_backward_until(&@filter) or self')
  end

  it "doesn't match the [*item] idiom" do
    OperatorSpacing.should_not warn('[*args]')
  end

  it 'has a reasonable description' do
    OperatorSpacing.new('(stdin)', 'a+ b').desc.should =~ /spacing/
  end

  OperatorSpacing::OPERATORS.each do |operator|
    describe "with #{operator}" do
      it "matches when there is no space on the left side" do
        OperatorSpacing.should warn("a#{operator} b")
      end

      it "matches when there is no space on the right side" do
        OperatorSpacing.should warn("a #{operator}b")
      end unless operator == '/'  # This confuses the shit out of the lexer

      it "matches when there is no space on both sides" do
        OperatorSpacing.should warn("a#{operator}b")
      end

      it "doesn't match when there is exactly one space on both sides" do
        OperatorSpacing.should_not warn("a #{operator} b")
      end

      describe 'when fixing' do
        it 'changes nothing when there is one space on both sides' do
          OperatorSpacing.should correct_to("a #{operator} b", "a #{operator} b")
        end

        it 'fixes by inserting an extra space on the left' do
          OperatorSpacing.should correct_to("a#{operator} b", "a #{operator} b")
        end

        it 'fixes by inserting an extra space on the right' do
          OperatorSpacing.should correct_to("a #{operator}b", "a #{operator} b")
        end unless operator == '/'  # This confuses the shit out of the lexer

        it 'fixes by inserting an extra space on both sides' do
          OperatorSpacing.should correct_to("a#{operator}b", "a #{operator} b")
        end
      end
    end
  end
end