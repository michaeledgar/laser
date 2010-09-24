require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe InlineCommentSpaceWarning do
  SETTINGS = {InlineCommentSpaceWarning::OPTION_KEY => 2, :indent_size => 2}
  it 'is a line-based warning' do
    InlineCommentSpaceWarning.new('(stdin)', 'hello').should be_a(LineWarning)
  end

  it 'matches when there are less than 2 spaces between code and comment' do
    InlineCommentSpaceWarning.should warn('a + b#comment', SETTINGS)
    InlineCommentSpaceWarning.should warn('a + b # comment', SETTINGS)
    InlineCommentSpaceWarning.should_not warn('a + b  # comment', SETTINGS)
    InlineCommentSpaceWarning.should_not warn('a +b  # wool: ignore OperatorSpacing', SETTINGS)
  end

  it 'has a remotely useful description' do
    InlineCommentSpaceWarning.new('(stdin)', 'hello  #').desc.should =~ /inline.*comment/i
  end

  context 'when fixing' do
    before do
      @warning = InlineCommentSpaceWarning.new('(stdin)', 'a + b  ')
      @tab_warning = InlineCommentSpaceWarning.new('(stdin)', "a + b\t\t")
    end
  end
end