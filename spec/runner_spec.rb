require_relative 'spec_helper'

describe Runner do
  before do
    @runner = Runner.new(['a', :b])
  end

  describe '#run' do
    it 'collects options and arguments, decides what to scan, scans, and displays' do
      runner = Runner.new(['--report-fixed', 'hello', 'world'])
      expected_settings = {:"report-fixed_given"=>true, :"report-fixed"=>true,
                           fix: false, help: false, debug: false,
                           InlineCommentSpaceWarning::OPTION_KEY => 2,
                           :"line-length" => nil, only: nil, stdin: false,
                           display: true, :"list-modules" => false, profile: false,
                           S: false, include: [],
                           __using__: Warning.all_warnings,
                           __fix__: Warning.all_warnings}
      scanner = mock(:scanner)
      Scanner.should_receive(:new, expected_settings).and_return(scanner)

      data1, data2 = mock(:data1), mock(:data2)
      warning1, warning2 = mock(:warning1), mock(:warning2)
      file1, file2 = mock(:file1), mock(:file2)

      scanner.should_receive(:settings).exactly(3).times.and_return({:"report-fixed" => true})
      File.should_receive(:read).with('hello').twice.and_return(data1)
      scanner.should_receive(:scan).
              with(data1, 'hello').
              and_return([warning1])
      warning1.should_receive(:to_ary)

      scanner.should_receive(:settings).and_return({})
      File.should_receive(:read).with('world').twice.and_return(data2)
      scanner.should_receive(:scan).
              with(data2, 'world').
              and_return([warning2])
      warning2.should_receive(:to_ary)

      runner.should_receive(:display_warnings).with([warning1, warning2], expected_settings)

      runner.run
    end
    
    it 'works with stdin: true' do
      runner = Runner.new(['--stdin', '--only', 'UselessDoubleQuotesWarning'])
      expected_settings = {:"report-fixed" => false, fix: false, help: false,
                           debug: false, InlineCommentSpaceWarning::OPTION_KEY => 2,
                           :"line-length" => nil, only: 'UselessDoubleQuotesWarning',
                           stdin: true, stdin_given: true, only_given: true,
                           display: true, :"list-modules" => false, profile: false,
                           S: false, include: [],
                           __using__: [UselessDoubleQuotesWarning],
                           __fix__: [UselessDoubleQuotesWarning]}
      scanner = mock(:scanner)
      Scanner.should_receive(:new, expected_settings).and_return(scanner)

      data1 = mock(:data1)
      warning1 = mock(:warning1)

      scanner.should_receive(:settings).twice.and_return({:"report-fixed" => true})
      STDIN.should_receive(:read).twice.and_return(data1)
      scanner.should_receive(:scan).
              with(data1, '(stdin)').
              and_return([warning1])
      warning1.should_receive(:to_ary)

      runner.should_receive(:display_warnings).with([warning1], expected_settings)
      runner.run
    end
    
    it 'works with --list-modules' do
      output = swizzling_io do
        runner = Runner.new(['--list-modules'])
        runner.run
      end
      modules = output.split("\n")[2..-1]
      modules.should_not be_empty
      modules.should == modules.sort
      ["Array < Object", "Module < Object", "Proc < Object", "Class < Module", "Object < BasicObject"].each do |mod|
        modules.should include(mod)
      end
    end
  end

  describe '#collect_options_and_arguments' do
    before do
      @runner = Runner.new(['--fix', '--report-fixed', '--line-length', '103', 'hello', 'there'])
      @settings, @arguments = @runner.collect_options_and_arguments
    end

    after do
      new_warning = current = Warning.all_warnings.find do |warning|
        warning.superclass == GenericLineLengthWarning && warning.line_length_limit == 103
      end
      while (current = current.superclass) && current != Warning.superclass
        current.all_warnings.delete new_warning
      end if current
    end

    it 'finds both flags' do
      @settings[:fix].should be_true
      @settings[:"report-fixed"].should be_true
      @settings[:"line-length"].should == 103
    end

    it 'finds both stray arguments' do
      @arguments.should == ['hello', 'there']
    end
  end

  describe '#swizzling_argv' do
    it 'changes ARGV to the runner\'s argv value' do
      @runner.swizzling_argv do
        ARGV.should == ['a', :b]
      end
    end

    it 'restores ARGV despite an exception' do
      old_argv = ARGV.dup
      expect {
        @runner.swizzling_argv do
          raise SystemExit.new('exiting')
        end
      }.to raise_error(SystemExit)
      ARGV.should == old_argv
    end
  end

  describe '#get_settings' do
    it 'has a --fix option' do
      runner = Runner.new(['--fix'])
      settings = runner.swizzling_argv { runner.get_settings }
      settings[:fix].should be_true
      settings[:fix_given].should be_true
    end

    it 'has a --report-fixed option' do
      runner = Runner.new(['--report-fixed'])
      settings = runner.swizzling_argv { runner.get_settings }
      settings[:"report-fixed"].should be_true
      settings[:"report-fixed_given"].should be_true
    end
  end

  describe '#handle_global_options' do
    it 'specifies :using and :fix when :only is provided' do
      runner = Runner.new([])
      runner.handle_global_options(only: 'UselessDoubleQuotesWarning')
      runner.using.should == [UselessDoubleQuotesWarning]
      runner.fix.should == [UselessDoubleQuotesWarning]
    end
    
    it 'works with multiple short names' do
      runner = Runner.new([])
      runner.handle_global_options(only: 'ST1,ST3')
      runner.using.size.should == 2
      runner.using.each {|w| w.ancestors.should include(Warning) }
    end
  end
  
  describe '#convert_warning_list' do
    it 'should have a :whitespace helper' do
      result = @runner.convert_warning_list([:whitespace])
      list = ExtraBlankLinesWarning, ExtraWhitespaceWarning, 
             OperatorSpacing, MisalignedUnindentationWarning
      (result & list).should == list
    end
    
    it 'should have an :all option' do
      @runner.convert_warning_list([:all]).should == Warning.all_warnings
    end
  end

  describe '#display_warnings' do
    it 'prints the lines and files where there are warnings' do
      warning = Warning.new('hello', 'a+b')
      warning.line_number = 4
      warning.severity = 3
      warnings = [warning]
      runner = Runner.new(['temp', 'hello'])
      output = swizzling_io do
        runner.display_warnings(warnings, {})
      end
      output.should =~ /hello:4/
      output.should =~ /(3)/
      output.should =~ /Warning/
      output.should =~ /1 warning/
      output.should =~ /0 are fixable/
    end
  end

  describe '#collect_warnings' do
    it 'scans each file provided' do
      scanner = mock(:scanner)
      data1, data2 = mock(:data1), mock(:data2)
      warning_list1, warning_list2 = mock(:wl1), mock(:wl2)
      File.should_receive(:read).with('abc').and_return(data1)
      scanner.should_receive(:settings).exactly(4).times.and_return({})
      scanner.should_receive(:scan).with(data1, 'abc').and_return(warning_list1)
      warning_list1.should_receive(:to_ary)
      File.should_receive(:read).with('def').and_return(data2)
      scanner.should_receive(:scan).with(data2, 'def').and_return(warning_list2)
      warning_list2.should_receive(:to_ary)

      @runner.collect_warnings(['abc', 'def'], scanner).should == [warning_list1, warning_list2]
    end
  end
end