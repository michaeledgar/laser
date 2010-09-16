require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ExtraBlankLinesWarning do
  it 'is a file-based warning' do
    ExtraBlankLinesWarning.new('(stdin)', 'hello').should be_a(FileWarning)
    FileWarning.all_warnings.should include(ExtraBlankLinesWarning)
  end

  it 'matches when there is a single empty blank line' do
    ExtraBlankLinesWarning.should warn("a + b\n")
  end

  it 'matches when there is a single blank line with spaces' do
    ExtraBlankLinesWarning.should warn("a + b\n  ")
  end

  it 'matches when there is are multiple blank lines' do
    ExtraBlankLinesWarning.should warn("a + b\n  \n\t\n")
  end

  it 'counts the number of blank lines' do
    ExtraBlankLinesWarning.new('(stdin)', "a + b\n").count_extra_lines.should == 1
    ExtraBlankLinesWarning.new('(stdin)', "a + b\n\t\n").count_extra_lines.should == 2
    ExtraBlankLinesWarning.new('(stdin)', "a + b\n\n").count_extra_lines.should == 2
    ExtraBlankLinesWarning.new('(stdin)', "a + b\n  \n\n").count_extra_lines.should == 3
    ExtraBlankLinesWarning.new('(stdin)', "a + b\n  \n\t\n").count_extra_lines.should == 3
    ExtraBlankLinesWarning.new('(stdin)', "a + b\n\n\n\n\n").count_extra_lines.should == 5
  end

  it 'has a remotely useful description' do
    ExtraBlankLinesWarning.new('(stdin)', 'hello  ').desc.should =~ /blank line/
  end

  WARNINGS = @warnings = [ ExtraBlankLinesWarning.new('(stdin)', "a + b\n\n\t  \t\n\t  "),
                ExtraBlankLinesWarning.new('(stdin)', "a + b\n  \n\t\n"),
                ExtraBlankLinesWarning.new('(stdin)', "a + b\n  \n\n"),
                ExtraBlankLinesWarning.new('(stdin)', "a + b\n\n\n\n\n"),
                ExtraBlankLinesWarning.new('(stdin)', "a + b\n"),
                ExtraBlankLinesWarning.new('(stdin)', "a + b\n  ") ]

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
  class SemicolonWarning < LineWarning

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
      @warning = ExtraBlankLinesWarning.new('(stdin)', invalid)
    end

    it 'only removes the trailing whitespace' do
      @warning.fix(nil).should == @original
    end
  end
end