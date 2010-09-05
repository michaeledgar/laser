require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::ExtraWhitespaceWarning do
  it 'matches when there are spaces at the end of a line' do
    Wool::ExtraWhitespaceWarning.match?('a + b  ', nil).should be_true
    Wool::ExtraWhitespaceWarning.match?('a + b ', nil).should be_true
    Wool::ExtraWhitespaceWarning.match?('a + b', nil).should be_false
  end
  
  it 'matches when there are tabs at the end of a line' do
    Wool::ExtraWhitespaceWarning.match?("a + b\t\t", nil).should be_true
    Wool::ExtraWhitespaceWarning.match?("a + b\t", nil).should be_true
    Wool::ExtraWhitespaceWarning.match?("a + b", nil).should be_false
  end
  
  it 'has a remotely useful description' do
    Wool::ExtraWhitespaceWarning.new('(stdin)', 'hello  ').desc.should =~ /whitespace/
  end
  
  context 'when fixing' do
    before do
      @warning = Wool::ExtraWhitespaceWarning.new('(stdin)', 'a + b  ')
      @tab_warning = Wool::ExtraWhitespaceWarning.new('(stdin)', "a + b\t\t")
    end
    
    it 'fixes by removing extra spaces' do
      @warning.fix(nil).should == 'a + b'
    end
    
    it 'fixes by removing extra tabs' do
      @tab_warning.fix(nil).should == 'a + b'
    end
  end
end
