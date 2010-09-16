require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::SemicolonWarning do
  it 'is a line-based warning' do
    Wool::SemicolonWarning.new('(stdin)', 'hello').should be_a(Wool::LineWarning)
  end

  it 'matches when a semicolon splits two expressions' do
    Wool::SemicolonWarning.should warn('puts x; puts y')
  end

  it 'matches when a semicolon splits two expressions that have strings' do
    Wool::SemicolonWarning.should warn('puts "x"; puts "y"')
  end

  it "doesn't match when a semicolon is in a string" do
    Wool::SemicolonWarning.should_not warn('puts "x;y"')
  end

  it "doesn't match when a semicolon is in a single-quoted string" do
    Wool::SemicolonWarning.should_not warn("puts 'x;y'")
  end

  it "doesn't match when a semicolon is used in an Exception definition" do
    Wool::SemicolonWarning.should_not warn('class AError < BError; end"')
  end

  it 'has a lower severity when quotes are involved due to unsure-ness' do
    Wool::SemicolonWarning.new('(stdin)', "hello' world' ; there").severity.should <
    Wool::SemicolonWarning.new('(stdin)', 'hello world ; there').severity
  end

  it 'has a remotely descriptive description' do
    Wool::SemicolonWarning.new('(stdin)', 'hello ; world').desc.should =~ /semicolon/
  end

  it "doesn't match when a semicolon is in a comment" do
    Wool::SemicolonWarning.should_not warn("hello # indeed; i agree")
  end
  
  context '#fix' do
    it 'converts the simplest semicolon use to two lines' do
      Wool::SemicolonWarning.new('(stdin)', 'a;b').fix.should == "a\nb"
    end
    
    it 'converts the simplest triple semicolon use to two lines' do
      Wool::SemicolonWarning.new('(stdin)', 'a;b;c').fix.should == "a\nb\nc"
    end
    
    it 'maintains indentation on new lines' do
      Wool::SemicolonWarning.new('(stdin)', '  a;b').fix.should == "  a\n  b"
    end
    
    it 'maintains indentation on all new lines' do
      Wool::SemicolonWarning.new('(stdin)', '  a;b;c').fix.should == "  a\n  b\n  c"
    end
  end
end