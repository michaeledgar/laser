require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::GenericLineLengthWarning do
  before do
    @eighty_cap = Class.new(Wool::GenericLineLengthWarning)
    @eighty_cap.line_length_limit = 80
  end

  it 'is a line-based warning' do
    Wool::GenericLineLengthWarning.new('(stdin)', 'hello').should be_a(Wool::LineWarning)
  end

  it 'initializes to a file and line' do
    warning = @eighty_cap.new('(stdin)', 'x' * 81)
    warning.severity.should == @eighty_cap.severity
  end

  it 'has a remotely useful description' do
    @eighty_cap.new('(stdin)', 'x' * 80).desc.should =~ /line length/i
  end

  it 'matches lines longer than the specified number of characters' do
    @eighty_cap.match?('x' * 82, nil).should be_true
  end

  it 'does not match lines shorter than the specified number of characters' do
    @eighty_cap.match?('x' * 78, nil).should be_false
  end

  it 'does not match lines equal to the specified number of characters' do
    @eighty_cap.match?('x' * 80, nil).should be_false
  end
  
  context 'when fixing' do
    before do
      @twenty_cap = Class.new(Wool::GenericLineLengthWarning)
      @twenty_cap.line_length_limit = 20
    end
    
    it "takes a line with just a comment on it and breaks it into many lines" do
      input = "# my comment is this and that and another thing"
      output = "# my comment is this\n# and that and\n# another thing"
      @twenty_cap.new('(stdin)', input).fix.should == output
    end
    
    it "creates new lines with the same indentation as the input" do
      input = "   # my comment is this and that and another thing"
      output = "   # my comment is\n   # this and that\n   # and another\n   # thing"
      @twenty_cap.new('(stdin)', input).fix.should == output
    end
    
    it 'uses the same number of hashes to denote the comment' do
      input = " ## my comment is this and that and another thing"
      output = " ## my comment is\n ## this and that\n ## and another\n ## thing"
      @twenty_cap.new('(stdin)', input).fix.should == output
    end
  end
end

describe 'Wool::LineLengthMaximum' do
  before do
    @hundred_cap = Wool::LineLengthMaximum(100)
  end

  it 'matches lines longer than the specified maximum' do
    @hundred_cap.match?('x' * 101, nil).should be_true
  end

  it 'has a high severity' do
    @hundred_cap.severity.should >= 7.5
  end

  it 'does not match lines smaller than the specified maximum' do
    @hundred_cap.match?('x' * 100, nil).should be_false
  end
end

describe 'Wool::LineLengthWarning' do
  before do
    @hundred_cap = Wool::LineLengthWarning(80)
  end

  it 'matches lines longer than the specified maximum' do
    @hundred_cap.match?('x' * 81, nil).should be_true
  end

  it 'has a lower severity' do
    @hundred_cap.severity.should <= 4
  end

  it 'does not match lines smaller than the specified maximum' do
    @hundred_cap.match?('x' * 80, nil).should be_false
  end
end