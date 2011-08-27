require_relative 'spec_helper'

describe ParensOnDeclarationWarning do
  it 'is a file-based warning' do
    ParensOnDeclarationWarning.new('(stdin)', 'hello').should be_a(FileWarning)
  end

  context 'with a normal method definition' do
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
  end
  
  context 'with a singleton definition' do
    it 'matches when a method has arguments with no parens around them' do
      ParensOnDeclarationWarning.should warn('def self.abc arg; end')
    end

    it 'matches when a method with no arguments is declared with parentheses' do
      ParensOnDeclarationWarning.should warn('def self.abc(); end')
    end

    it 'does not match when arguments are surrounded by parentheses' do
      ParensOnDeclarationWarning.should_not warn('def self.abc(arg); end')
    end

    it 'does not match when there are no arguments' do
      ParensOnDeclarationWarning.should_not warn('def self.abc; end')
    end

    describe '#desc' do
      it 'includes the name of the offending method' do
        matches = ParensOnDeclarationWarning.new('(stdin)', 'def self.silly_monkey arg1, *rest; end').match?
        matches[0].desc.should =~ /silly_monkey/
      end
    end
  end
end
