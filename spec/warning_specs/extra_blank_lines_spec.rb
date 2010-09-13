require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::ExtraBlankLinesWarning do
  it 'is a file-based warning' do
    Wool::ExtraBlankLinesWarning.new('(stdin)', 'hello').should be_a(Wool::FileWarning)
    Wool::FileWarning.all_warnings.should include(Wool::ExtraBlankLinesWarning)
  end

  it 'matches when there is a single empty blank line' do
    Wool::ExtraBlankLinesWarning.match?("a + b\n", nil).should be_true
  end

  it 'matches when there is a single blank line with spaces' do
    Wool::ExtraBlankLinesWarning.match?("a + b\n  ", nil).should be_true
  end

  it 'matches when there is are multiple blank lines' do
    Wool::ExtraBlankLinesWarning.match?("a + b\n  \n\t\n", nil).should be_true
  end

  it 'counts the number of blank lines' do
    Wool::ExtraBlankLinesWarning.new('(stdin)', "a + b\n").count_extra_lines.should == 1
    Wool::ExtraBlankLinesWarning.new('(stdin)', "a + b\n\t\n").count_extra_lines.should == 2
    Wool::ExtraBlankLinesWarning.new('(stdin)', "a + b\n\n").count_extra_lines.should == 2
    Wool::ExtraBlankLinesWarning.new('(stdin)', "a + b\n  \n\n").count_extra_lines.should == 3
    Wool::ExtraBlankLinesWarning.new('(stdin)', "a + b\n  \n\t\n").count_extra_lines.should == 3
    Wool::ExtraBlankLinesWarning.new('(stdin)', "a + b\n\n\n\n\n").count_extra_lines.should == 5
  end

  it 'has a remotely useful description' do
    Wool::ExtraBlankLinesWarning.new('(stdin)', 'hello  ').desc.should =~ /blank line/
  end

  WARNINGS = @warnings = [ Wool::ExtraBlankLinesWarning.new('(stdin)', "a + b\n\n\t  \t\n\t  "),
                Wool::ExtraBlankLinesWarning.new('(stdin)', "a + b\n  \n\t\n"),
                Wool::ExtraBlankLinesWarning.new('(stdin)', "a + b\n  \n\n"),
                Wool::ExtraBlankLinesWarning.new('(stdin)', "a + b\n\n\n\n\n"),
                Wool::ExtraBlankLinesWarning.new('(stdin)', "a + b\n"),
                Wool::ExtraBlankLinesWarning.new('(stdin)', "a + b\n  ") ]

  WARNINGS.each do |warning|
    context "When fixing #{warning.body.inspect}" do
      it 'fixes by removing all extra whitespace' do
        warning.fix(nil).should == 'a + b'
      end
    end
  end

  context 'when fixing a realistic multiline block' do
    before do
      @original = <<-EOF
    # Warning for using semicolons outside of class declarations.
  class Wool::SemicolonWarning < Wool::LineWarning

  def initialize(file, line)
    severity = line =~ /['"]/ ? 2 : 4
    super('Semicolon for multiple statements', file, line, 0, severity)
  end

  def desc
    'The line uses a semicolon to separate multiple statements outside of a class declaration.'
  end

end
EOF
      @original.strip!
      invalid = @original + "\n  \t\t\n  \n\n"
      @warning = Wool::ExtraBlankLinesWarning.new('(stdin)', invalid)
end

    it 'only removes the trailing whitespace' do
      @warning.fix(nil).should == @original
    end
end
end
