require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::ExtraWhitespaceWarning do
  it 'is a line-based warning' do
    Wool::ExtraWhitespaceWarning.new('(stdin)', 'hello').should be_a(Wool::LineWarning)
  end

  it 'matches when there are spaces at the end of a line' do
    Wool::ExtraWhitespaceWarning.should warn('a + b  ')
    Wool::ExtraWhitespaceWarning.should warn('a + b ')
    Wool::ExtraWhitespaceWarning.should_not warn('a + b')
  end

  it 'matches when there are tabs at the end of a line' do
    Wool::ExtraWhitespaceWarning.should warn("a + b\t\t")
    Wool::ExtraWhitespaceWarning.should warn("a + b\t")
    Wool::ExtraWhitespaceWarning.should_not warn('a + b')
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