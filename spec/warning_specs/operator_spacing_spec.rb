require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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
  end

  it "doesn't match the [*item] idiom" do
    OperatorSpacing.should_not warn('[*args]')
  end

  it 'has a reasonable description' do
    OperatorSpacing.new('(stdin)', 'a+ b').desc.should =~ /spacing/
  end

  context '#remove_regexes' do
    it 'removes a simple regex' do
      OperatorSpacing.new('(stdin)', '').remove_regexes('/a+b/').should == 'nil'
    end

    it 'does not remove a simple division' do
      OperatorSpacing.new('(stdin)', '').remove_regexes('3 / 4 / 5').should == '3 / 4 / 5'
    end

    with_examples ['{:a => /hello/}', '{:a => nil}'], [', /hello/', ', nil'],
                  ['say(/hello/)', 'say(nil)'], ['say(/hello/)', 'say(nil)'],
                  ['say /hello/', 'say nil'], ['say! /hello/', 'say! nil'] do |input, output|
    it "removes the regex in #{input.inspect}" do
          OperatorSpacing.new('(stdin)', '').remove_regexes(input).should == output
    end
    end

    it 'removes a simple %r regex' do
      OperatorSpacing.new('(stdin)', '').remove_regexes('%r|a+b|').should == 'nil'
    end

    with_examples ['[', ']'], ['{', '}'], ['(', ')'], ['!', '!'] do |left, right|
      it "removes a %r#{left}#{right} regex" do
        OperatorSpacing.new('(stdin)', '').remove_regexes("%r#{left}a+b#{right}").should == 'nil'
      end
    end
  end

  OperatorSpacing::OPERATORS.each do |operator|
    context "with #{operator}" do
      it "matches when there is no space on the left side" do
        OperatorSpacing.should warn("a#{operator} b")
      end

      it "matches when there is no space on the right side" do
        OperatorSpacing.should warn("a #{operator}b")
      end

      it "matches when there is no space on both sides" do
        OperatorSpacing.should warn("a#{operator}b")
      end

      it "doesn't match when there is exactly one space on both sides" do
        OperatorSpacing.should_not warn("a #{operator} b")
      end

      context 'when fixing' do
        before do
          @warning_1 = OperatorSpacing.new('(stdin)', "a #{operator} b")
          @warning_2 = OperatorSpacing.new('(stdin)', "a#{operator} b")
          @warning_3 = OperatorSpacing.new('(stdin)', "a #{operator}b")
          @warning_4 = OperatorSpacing.new('(stdin)', "a#{operator}b")
        end

        it 'changes nothing when there is one space on both sides' do
          @warning_1.fix(nil).should == "a #{operator} b"
        end

        it 'fixes by inserting an extra space on the left' do
          @warning_2.fix(nil).should == "a #{operator} b"
        end

        it 'fixes by inserting an extra space on the right' do
          @warning_3.fix(nil).should == "a #{operator} b"
        end

        it 'fixes by inserting an extra space on both sides' do
          @warning_4.fix(nil).should == "a #{operator} b"
        end
      end
    end
  end
end