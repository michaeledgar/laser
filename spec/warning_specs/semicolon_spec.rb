require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::SemicolonWarning do
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
end
