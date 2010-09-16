require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::OperatorSpacing do
  it 'is a line-based warning' do
    Wool::OperatorSpacing.new('(stdin)', 'hello').should be_a(Wool::LineWarning)
  end

  it "doesn't match block declarations" do
    Wool::OperatorSpacing.new('(stdin)', '[1, 2].each { |x| p x }').match?.should be_false
    Wool::OperatorSpacing.new('(stdin)', '[1, 2].each {| y | p x }').match?.should be_false
    Wool::OperatorSpacing.new('(stdin)', "[1, 2].each do |x|\n p x\nend").match?.should be_false
    Wool::OperatorSpacing.new('(stdin)', "[1, 2].each do|x|\n p x\nend").match?.should be_false
  end

  it "doesn't match in a comment" do
    Wool::OperatorSpacing.new('(stdin)', 'hello # a+b').match?.should be_false
  end

  it "doesn't match a <<- heredoc" do
    Wool::OperatorSpacing.new('(stdin)', '@original = <<-EOF').match?.should be_false
  end

  it "doesn't match a << heredoc" do
    Wool::OperatorSpacing.new('(stdin)', '@original = <<EOF').match?.should be_false
  end

  it "doesn't match adjacent negative numbers" do
    Wool::OperatorSpacing.new('(stdin)', '  exit(-1)').match?.should be_false
  end

  it "doesn't match *args in block parameters" do
    Wool::OperatorSpacing.new('(stdin)', 'list.each do |*args|').match?.should be_false
    Wool::OperatorSpacing.new('(stdin)', 'list.each { |*args| }').match?.should be_false
  end

  it "doesn't match splat arguments" do
    Wool::OperatorSpacing.new('(stdin)', 'x.call(*args)').match?.should be_false
    Wool::OperatorSpacing.new('(stdin)', 'x.call(a, *args)').match?.should be_false
    Wool::OperatorSpacing.new('(stdin)', 'x.call(*args, b)').match?.should be_false
    Wool::OperatorSpacing.new('(stdin)', 'x.call(a, *args, b)').match?.should be_false
  end

  it "does match multiplication in an argument list" do
    Wool::OperatorSpacing.new('(stdin)', 'x.call(a *b)').match?.should be_true
    Wool::OperatorSpacing.new('(stdin)', 'x.call(x, a *b)').match?.should be_true
    Wool::OperatorSpacing.new('(stdin)', 'x.call(a *b, z)').match?.should be_true
  end

  it "doesn't match block arguments" do
    Wool::OperatorSpacing.new('(stdin)', 'x.call(&b)').match?.should be_false
    Wool::OperatorSpacing.new('(stdin)', 'x.call(a, &b)').match?.should be_false
    Wool::OperatorSpacing.new('(stdin)', 'x.call(&b, b)').match?.should be_false
    Wool::OperatorSpacing.new('(stdin)', 'x.call(a, &b, b)').match?.should be_false
  end

  it "doesn't match the [*item] idiom" do
    Wool::OperatorSpacing.new('(stdin)', '[*args]').match?.should be_false
  end

  it 'has a reasonable description' do
    Wool::OperatorSpacing.new('(stdin)', 'a+ b').desc.should =~ /spacing/
  end

  context '#remove_regexes' do
    it 'removes a simple regex' do
      Wool::OperatorSpacing.new('(stdin)', '').remove_regexes('/a+b/').should == 'nil'
    end

    it 'does not remove a simple division' do
      Wool::OperatorSpacing.new('(stdin)', '').remove_regexes('3 / 4 / 5').should == '3 / 4 / 5'
    end

    with_examples ['{:a => /hello/}', '{:a => nil}'], [', /hello/', ', nil'],
                  ['say(/hello/)', 'say(nil)'], ['say(/hello/)', 'say(nil)'],
                  ['say /hello/', 'say nil'], ['say! /hello/', 'say! nil'] do |input, output|
    it "removes the regex in #{input.inspect}" do
          Wool::OperatorSpacing.new('(stdin)', '').remove_regexes(input).should == output
    end
    end

    it 'removes a simple %r regex' do
      Wool::OperatorSpacing.new('(stdin)', '').remove_regexes('%r|a+b|').should == 'nil'
    end

    with_examples ['[', ']'], ['{', '}'], ['(', ')'], ['!', '!'] do |left, right|
      it "removes a %r#{left}#{right} regex" do
        Wool::OperatorSpacing.new('(stdin)', '').remove_regexes("%r#{left}a+b#{right}").should == 'nil'
      end
    end
  end

  Wool::OperatorSpacing::OPERATORS.each do |operator|
    context "with #{operator}" do
      it "matches when there is no space on the left side" do
        Wool::OperatorSpacing.new('(stdin)', "a#{operator} b").match?.should be_true
      end

      it "matches when there is no space on the right side" do
        Wool::OperatorSpacing.new('(stdin)', "a #{operator}b").match?.should be_true
      end

      it "matches when there is no space on both sides" do
        Wool::OperatorSpacing.new('(stdin)', "a#{operator}b").match?.should be_true
      end

      it "doesn't match when there is exactly one space on both sides" do
        Wool::OperatorSpacing.new('(stdin)', "a #{operator} b").match?.should be_false
      end

      context 'when fixing' do
        before do
          @warning_1 = Wool::OperatorSpacing.new('(stdin)', "a #{operator} b")
          @warning_2 = Wool::OperatorSpacing.new('(stdin)', "a#{operator} b")
          @warning_3 = Wool::OperatorSpacing.new('(stdin)', "a #{operator}b")
          @warning_4 = Wool::OperatorSpacing.new('(stdin)', "a#{operator}b")
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