require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe UselessDoubleQuotesWarning do
  it 'is a file-based warning' do
    UselessDoubleQuotesWarning.new('(stdin)', 'hello').should be_a(FileWarning)
  end

  it 'matches when a simple string is in double quotes unnecessarily' do
    UselessDoubleQuotesWarning.should warn('simple "example, okay?"')
  end
  
  it 'matches when a simple string is in %Q{} unnecessarily' do
    UselessDoubleQuotesWarning.should warn('simple %Q{example, okay?}')
  end
  
  it 'does not match when an escape sequence is used' do
    UselessDoubleQuotesWarning.should_not warn('simple "example\n okay?"')
  end
  
  it 'does not match when an apostrophe is present' do
    UselessDoubleQuotesWarning.should_not warn('simple "example\' okay?"')
  end
  
  it 'does not match when text interpolation is used' do
    UselessDoubleQuotesWarning.should_not warn('simple "exaple\n #{h stuff} okay?"')
  end
  
  it 'does match when a useless double-quoted string is used inside text interpolation' do
    UselessDoubleQuotesWarning.should warn('simple "example, #{h "guy"} okay?"')
  end
  
  it 'does not warn about single quotes that are nice and simple' do
    UselessDoubleQuotesWarning.should_not warn("simple 'string is okay'")
  end
  
  it 'does not warn about %q syntax that are simple' do
    UselessDoubleQuotesWarning.should_not warn("simple %q{string is okay}")
  end

  # it 'matches when a semicolon splits two expressions that have strings' do
  #   SemicolonWarning.should warn('puts "x"; puts "y"')
  # end
  #
  # it "doesn't match when a semicolon is in a string" do
  #   SemicolonWarning.should_not warn('puts "x;y"')
  # end
  #
  # it "doesn't match when a semicolon is in a single-quoted string" do
  #   SemicolonWarning.should_not warn("puts 'x;y'")
  # end
  #
  # it "doesn't match when a semicolon is used in an Exception definition" do
  #   SemicolonWarning.should_not warn('class AError < BError; end"')
  # end
  #
  # it 'has a lower severity when quotes are involved due to unsure-ness' do
  #   SemicolonWarning.new('(stdin)', "hello' world' ; there").severity.should <
  #   SemicolonWarning.new('(stdin)', 'hello world ; there').severity
  # end
  #
  # it 'has a remotely descriptive description' do
  #   SemicolonWarning.new('(stdin)', 'hello ; world').desc.should =~ /semicolon/
  # end
  #
  # it "doesn't match when a semicolon is in a comment" do
  #   SemicolonWarning.should_not warn("hello # indeed; i agree")
  # end

  
end