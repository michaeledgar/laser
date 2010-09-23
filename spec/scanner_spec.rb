require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'stringio'

describe Wool::Scanner do
  before do
    @scanner = Wool::Scanner.new

    @fix_scanner_stdout = StringIO.new
    @fix_scanner = Wool::Scanner.new(:fix => true, :output_file => @fix_scanner_stdout)
  end

  context '#scan' do
    it 'takes an input and gathers warnings about it' do
      warnings = @scanner.scan('a + b ', '(stdin)')
      warnings.size.should == 1
      warnings[0].should be_a(Wool::ExtraWhitespaceWarning)
    end
    
    it "ignores warnings specified in the line's comments by class name" do
      warnings = @scanner.scan('a +b # wool: ignore OperatorSpacing')
      warnings.size.should == 0
    end
    
    it "ignores warnings specified in the line's comments by short name" do
      warnings = @scanner.scan("a +b # wool: ignore #{OperatorSpacing.short_name}")
      warnings.size.should == 0
    end
    
    it "ignores multiple warnings that are marked in the line's comments" do
      warnings = @scanner.scan(
          'a +b; c + d # wool: ignore OperatorSpacing SemicolonWarning')
      warnings.size.should == 0
    end

    it "ignores multiple warnings in the line's comments as short name" do
      warnings = @scanner.scan(
          "a +b; c + d # wool: ignore #{OperatorSpacing.short_name} #{SemicolonWarning.short_name}")
      warnings.size.should == 0
    end
    
    it 'fixes the input and writes it to :output_file' do
      warnings = @fix_scanner.scan('a + b ', '(stdin)')
      warnings.size.should == 1
      warnings[0].should be_a(Wool::ExtraWhitespaceWarning)
      @fix_scanner_stdout.string.should == "a + b"
    end

    it 'fixes multiple errors on one line' do
      warnings = @fix_scanner.scan('a +b ', '(stdin)')
      warnings.size.should == 2
      @fix_scanner_stdout.string.should == "a + b"
    end

    it 'fixes multiline inputs' do
      warnings = @fix_scanner.scan("def plus(a, b)\n  a + b \nend", '(stdin)')
      warnings.size.should == 1
      warnings[0].should be_a(Wool::ExtraWhitespaceWarning)
      @fix_scanner_stdout.string.should == "def plus(a, b)\n  a + b\nend"
    end

    it 'fixes multiline mis-indented inputs' do
      warnings = @fix_scanner.scan("def plus(a, b)\n  a + b\n end", '(stdin)')
      warnings.size.should == 1
      warnings[0].should be_a(Wool::MisalignedUnindentationWarning)
      @fix_scanner_stdout.string.should == "def plus(a, b)\n  a + b\nend"
    end

    it 'fixes class definitions' do
      warnings = @fix_scanner.scan("class Hello\n  a+b\nend", '(stdin)')
      warnings.size.should == 1
      warnings[0].should be_a(Wool::OperatorSpacing)
      @fix_scanner_stdout.string.should == "class Hello\n  a + b\nend"
    end
  end
end