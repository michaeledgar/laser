require_relative 'spec_helper'

describe SemicolonWarning do
  it 'is a line-based warning' do
    SemicolonWarning.new('(stdin)', 'hello').should be_a(LineWarning)
  end

  it 'matches when a semicolon splits two expressions' do
    SemicolonWarning.should warn('puts x; puts y')
  end

  it 'matches when a semicolon splits two expressions that have strings' do
    SemicolonWarning.should warn('puts "x"; puts "y"')
  end

  it "doesn't match when a semicolon is in a string" do
    SemicolonWarning.should_not warn('puts "x;y"')
  end

  it "doesn't match when a semicolon is in a single-quoted string" do
    SemicolonWarning.should_not warn("puts 'x;y'")
  end

  it "doesn't match when a semicolon is used in an Exception definition" do
    SemicolonWarning.should_not warn('class AError < BError; end"')
  end

  it 'has a lower severity when quotes are involved due to unsure-ness' do
    SemicolonWarning.new('(stdin)', "hello' world' ; there").severity.should <
    SemicolonWarning.new('(stdin)', 'hello world ; there').severity
  end

  it 'has a remotely descriptive description' do
    SemicolonWarning.new('(stdin)', 'hello ; world').desc.should =~ /semicolon/
  end

  it "doesn't match when a semicolon is in a comment" do
    SemicolonWarning.should_not warn("hello # indeed; i agree")
  end

  describe '#fix' do
    it 'converts the simplest semicolon use to two lines' do
      SemicolonWarning.should correct_to('a;b', "a\nb")
    end

    it 'converts the simplest triple semicolon use to two lines' do
      SemicolonWarning.should correct_to('a;b;c', "a\nb\nc")
    end

    it 'maintains indentation on new lines' do
      SemicolonWarning.should correct_to('  a;b', "  a\n  b")
    end

    it 'maintains indentation on all new lines' do
      SemicolonWarning.should correct_to('  a;b;c', "  a\n  b\n  c")
    end
  end
end