require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Runner do
  before do
    @runner = Runner.new(['a', :b])
  end

  context '#run' do
    it 'collects options and arguments, decides what to scan, scans, and displays' do
      runner = Runner.new(['--report-fixed', 'hello', 'world'])
      expected_settings = {:"report-fixed_given"=>true, :"report-fixed"=>true,
                           :fix => false, :help => false, :debug => false,
                           InlineCommentSpaceWarning::OPTION_KEY => 2,
                           :__using__ => Warning.all_warnings,
                           :__fix__ => Warning.all_warnings}
      scanner = mock(:scanner)
      Scanner.should_receive(:new, expected_settings).and_return(scanner)

      data1, data2 = mock(:data1), mock(:data2)
      warning1, warning2 = mock(:warning1), mock(:warning2)
      file1, file2 = mock(:file1), mock(:file2)

      scanner.should_receive(:settings).exactly(3).times.and_return({:"report-fixed" => true})
      File.should_receive(:read).with('hello').and_return(data1)
      scanner.should_receive(:scan).
              with(data1, 'hello').
              and_return([warning1])
      warning1.should_receive(:to_ary)

      scanner.should_receive(:settings).and_return({})
      File.should_receive(:read).with('world').and_return(data2)
      scanner.should_receive(:scan).
              with(data2, 'world').
              and_return([warning2])
      warning2.should_receive(:to_ary)

      runner.should_receive(:display_warnings).with([warning1, warning2], expected_settings)

      runner.run
    end
  end

  context '#collect_options_and_arguments' do
    before do
      @runner = Runner.new(['--fix', '--report-fixed', 'hello', 'there'])
      @settings, @arguments = @runner.collect_options_and_arguments
    end

    it 'finds both flags' do
      @settings[:fix].should be_true
      @settings[:"report-fixed"].should be_true
    end

    it 'finds both stray arguments' do
      @arguments.should == ['hello', 'there']
    end
  end

  context '#swizzling_argv' do
    it 'changes ARGV to the runner\'s argv value' do
      @runner.swizzling_argv do
        ARGV.should == ['a', :b]
      end
    end

    it 'restores ARGV despite an exception' do
      old_argv = ARGV.dup
      proc {
        @runner.swizzling_argv do
          raise SystemExit.new('exiting')
        end
      }.should raise_error(SystemExit)
      ARGV.should == old_argv
    end
  end

  context '#get_settings' do
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

  context '#display_warnings' do
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

  context '#collect_warnings' do
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