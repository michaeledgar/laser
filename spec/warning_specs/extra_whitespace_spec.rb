require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ExtraWhitespaceWarning do
  it 'is a line-based warning' do
    ExtraWhitespaceWarning.new('(stdin)', 'hello').should be_a(LineWarning)
  end

  it 'matches when there are spaces at the end of a line' do
    ExtraWhitespaceWarning.should warn('a + b  ')
    ExtraWhitespaceWarning.should warn('a + b ')
    ExtraWhitespaceWarning.should_not warn('a + b')
  end

  it 'matches when there are tabs at the end of a line' do
    ExtraWhitespaceWarning.should warn("a + b\t\t")
    ExtraWhitespaceWarning.should warn("a + b\t")
    ExtraWhitespaceWarning.should_not warn('a + b')
  end

  it 'has a remotely useful description' do
    ExtraWhitespaceWarning.new('(stdin)', 'hello  ').desc.should =~ /whitespace/
  end

  context 'when fixing' do
    before do
      @warning = ExtraWhitespaceWarning.new('(stdin)', 'a + b  ')
      @tab_warning = ExtraWhitespaceWarning.new('(stdin)', "a + b\t\t")
    end

    it 'fixes by removing extra spaces' do
      @warning.fix(nil).should == 'a + b'
    end

    it 'fixes by removing extra tabs' do
      @tab_warning.fix(nil).should == 'a + b'
    end
  end
end