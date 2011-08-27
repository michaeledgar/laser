require_relative 'spec_helper'

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

  describe '#desc' do
    it 'properly quotes the improperly quoted text' do
      matches = UselessDoubleQuotesWarning.new('(stdin)', 'simple "example, #{h "guy"} okay?"').match?
      matches[0].desc.should =~ /'guy'/
    end

    it 'properly quotes the improperly quoted text with %Q{}' do
      matches = UselessDoubleQuotesWarning.new('(stdin)', 'simple "example, #{h %Q{guy}} okay?"').match?
      matches[0].desc.should =~ /%q{guy}/
    end
  end

  describe '#fix' do
    it 'fixes a simple string using double quotes unnecessarily' do
      checker = UselessDoubleQuotesWarning.new('(stdin)', 'simple "example, okay?"')
      warnings = checker.match?
      warnings.size.should == 1
      warnings.first.fix('simple "example, okay?"').should == "simple 'example, okay?'"
    end
    
    it 'fixes a simple string using %Q{} unnecessarily' do
      checker = UselessDoubleQuotesWarning.new('(stdin)', 'simple %Q{example, okay?}')
      warnings = checker.match?
      warnings.size.should == 1
      warnings.first.fix('simple %Q{example, okay?}').should == "simple %q{example, okay?}"
    end
        
    it 'fixes a simple string inside a complex one' do
      checker = UselessDoubleQuotesWarning.new('(stdin)', 'simple "example, #{h "guy"} okay?"')
      warnings = checker.match?
      warnings.size.should == 1
      warnings.first.fix('simple "example, #{h "guy"} okay?"').should == 'simple "example, #{h \'guy\'} okay?"'
    end
  end
end
