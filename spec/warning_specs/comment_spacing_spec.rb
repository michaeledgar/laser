require_relative 'spec_helper'

describe InlineCommentSpaceWarning do
  SETTINGS = {InlineCommentSpaceWarning::OPTION_KEY => 2, :indent_size => 2}
  it 'is a line-based warning' do
    InlineCommentSpaceWarning.new('(stdin)', 'hello').should be_a(LineWarning)
  end

  it 'matches when there are less than 2 spaces between code and comment' do
    InlineCommentSpaceWarning.should warn('a + b#comment', SETTINGS)
    InlineCommentSpaceWarning.should warn('a + b # comment', SETTINGS)
    InlineCommentSpaceWarning.should_not warn('a + b  # comment', SETTINGS)
    InlineCommentSpaceWarning.should_not warn('a +b  # laser: ignore OperatorSpacing', SETTINGS)
  end

  it 'has an option to specify the necessary spacing' do
    InlineCommentSpaceWarning.options.size.should be > 0
    InlineCommentSpaceWarning.options[0].first.should ==
        InlineCommentSpaceWarning::OPTION_KEY
  end

  it 'respects the option for specifying the necessary spacing' do
    settings = {InlineCommentSpaceWarning::OPTION_KEY => 0}
    InlineCommentSpaceWarning.should warn('a + b # comment', settings)
    InlineCommentSpaceWarning.should_not warn('a + b# comment', settings)
  end
  
  it 'should not warn for improperly spaced comments that are inside comments' do
    InlineCommentSpaceWarning.should_not warn('#a + b   # comment', SETTINGS)
  end
  
  it 'should not warn for an empty comment at the start of a line' do
    InlineCommentSpaceWarning.should_not warn('#', SETTINGS)
  end

  it 'has a remotely useful description' do
    InlineCommentSpaceWarning.new('(stdin)', 'hello  #').desc.should =~ /inline.*comment/i
  end

  describe 'when fixing' do
    before do
      @settings = {InlineCommentSpaceWarning::OPTION_KEY => 2}
    end

    after do
      InlineCommentSpaceWarning.should correct_to(@input, @output, @settings)
    end

    it 'adds spaces when necessary' do
      @input = 'a + b#comment'
      @output = 'a + b  #comment'
    end

    it 'removes spaces when necessary' do
      @input = 'a + b        #comment'
      @output = 'a + b  #comment'
    end

    it 'respects the option for spacing' do
      @settings = {InlineCommentSpaceWarning::OPTION_KEY => 0}
      @input = 'a + b        #comment'
      @output = 'a + b#comment'
    end
  end
end
