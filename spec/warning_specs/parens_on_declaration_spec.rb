require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ParensOnDeclarationWarning do
  it 'is a file-based warning' do
    ParensOnDeclarationWarning.new('(stdin)', 'hello').should be_a(FileWarning)
  end

  it 'matches when a method has arguments with no parens around them' do
    ParensOnDeclarationWarning.should warn('def abc arg; end')
  end
  
  it 'matches when a method with no arguments is declared with parentheses' do
    ParensOnDeclarationWarning.should warn('def abc(); end')
  end

  it 'does not match when arguments are surrounded by parentheses' do
    ParensOnDeclarationWarning.should_not warn('def abc(arg); end')
  end
  
  it 'does not match when there are no arguments' do
    ParensOnDeclarationWarning.should_not warn('def abc; end')
  end

  describe '#desc' do
    it 'includes the name of the offending method' do
      matches = ParensOnDeclarationWarning.new('(stdin)', 'def silly_monkey arg1, *rest; end').match?
      matches[0].desc.should =~ /silly_monkey/
    end
  end

  # describe '#fix' do
  #   it 'fixes a simple string using double quotes unnecessarily' do
  #     checker = ParensOnDeclarationWarning.new('(stdin)', 'simple "example, okay?"')
  #     warnings = checker.match?
  #     warnings.size.should == 1
  #     warnings.first.fix('simple "example, okay?"').should == "simple 'example, okay?'"
  #   end
  #   
  #   it 'fixes a simple string using %Q{} unnecessarily' do
  #     checker = ParensOnDeclarationWarning.new('(stdin)', 'simple %Q{example, okay?}')
  #     warnings = checker.match?
  #     warnings.size.should == 1
  #     warnings.first.fix('simple %Q{example, okay?}').should == "simple %q{example, okay?}"
  #   end
  #       
  #   it 'fixes a simple string inside a complex one' do
  #     checker = ParensOnDeclarationWarning.new('(stdin)', 'simple "example, #{h "guy"} okay?"')
  #     warnings = checker.match?
  #     warnings.size.should == 1
  #     warnings.first.fix('simple "example, #{h "guy"} okay?"').should == 'simple "example, #{h \'guy\'} okay?"'
  #   end
  # end
end