require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::SemicolonWarning do
  it 'is a line-based warning' do
    Wool::SemicolonWarning.new('(stdin)', 'hello').should be_a(Wool::LineWarning)
  end
  
  it 'matches when a semicolon splits two expressions' do
    Wool::SemicolonWarning.match?('puts x; puts y', nil).should be_true
  end
  
  it 'matches when a semicolon splits two expressions that have strings' do
    Wool::SemicolonWarning.match?('puts "x"; puts "y"', nil).should be_true
  end
  
  it "doesn't match when a semicolon is in a string" do
    Wool::SemicolonWarning.match?('puts "x;y"', nil).should be_false
  end
  
  it "doesn't match when a semicolon is in a single-quoted string" do
    Wool::SemicolonWarning.match?("puts 'x;y'", nil).should be_false
  end
  
  it "doesn't match when a semicolon is used in an Exception definition" do
    Wool::SemicolonWarning.match?('class AError < BError; end"', nil).should be_false
  end
  
  it 'has a lower severity when quotes are involved due to unsure-ness' do
    Wool::SemicolonWarning.new('(stdin)', "hello' world' ; there").severity.should <
        Wool::SemicolonWarning.new('(stdin)', 'hello world ; there').severity
  end
  
  it 'has a remotely descriptive description' do
    Wool::SemicolonWarning.new('(stdin)', 'hello ; world').desc.should =~ /semicolon/
  end
end
