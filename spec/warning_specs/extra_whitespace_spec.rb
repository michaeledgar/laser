require_relative 'spec_helper'

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

  describe 'when fixing' do
    it 'fixes by removing extra spaces' do
      ExtraWhitespaceWarning.should correct_to('a + b  ', 'a + b')
    end

    it 'fixes by removing extra tabs' do
      ExtraWhitespaceWarning.should correct_to("a + b\t\t", 'a + b')
    end
  end
end
