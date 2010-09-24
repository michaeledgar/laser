require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe GenericLineLengthWarning do
  before do
    @eighty_cap = LineLengthCustomSeverity(80, 2)
    @eighty_cap.line_length_limit = 80
  end

  it 'is a line-based warning' do
    GenericLineLengthWarning.new('(stdin)', 'hello').should be_a(LineWarning)
  end

  it 'initializes to a file and line' do
    warning = @eighty_cap.new('(stdin)', 'x' * 81)
    warning.severity.should == @eighty_cap.severity
  end

  it 'has a remotely useful description' do
    @eighty_cap.new('(stdin)', 'x' * 80).desc.should =~ /line length/i
  end

  it 'matches lines longer than the specified number of characters' do
    @eighty_cap.should warn('x' * 82)
  end

  it 'does not match lines shorter than the specified number of characters' do
    @eighty_cap.should_not warn('x' * 78)
  end

  it 'does not match lines equal to the specified number of characters' do
    @eighty_cap.should_not warn('x' * 80)
  end

  context 'when fixing' do
    before do
      @twenty_cap = Class.new(GenericLineLengthWarning)
      @twenty_cap.line_length_limit = 20
      @settings = {}
    end

    after do
      @twenty_cap.should correct_to(@input, @output, @settings)
    end

    it 'takes a line with just a comment on it and breaks it into many lines' do
      @input = '# my comment is this and that and another thing'
      @output = "# my comment is this\n# and that and\n# another thing"
    end

    it 'creates new lines with the same indentation as the input' do
      @input = '   # my comment is this and that and another thing'
      @output = "   # my comment is\n   # this and that\n   # and another\n   # thing"
    end

    it 'uses the same number of hashes to denote the comment' do
      @input = ' ## my comment is this and that and another thing'
      @output = " ## my comment is\n ## this and that\n ## and another\n ## thing"
    end

    it 'splits up code with an overly long comment at the end' do
      @input = '  a + b # this is a stupidly long comment lol'
      @output = "  # this is a\n  # stupidly long\n  # comment lol\n  a + b"
    end

    it 'uses the same indentation and hashes for the new comment' do
      @input = ' a + b ### this is a stupidly long comment lol'
      @output = " ### this is a\n ### stupidly long\n ### comment lol\n a + b"
    end
    
    it 'fails to fix when if/unless are in a symbol' do
      # This came from an actual bug from running wool on wool's source.
      @input = "    left, right = @class.new('').split_on_keyword('x = 5 unless y == 2', :unless)"
      @output = @input
    end

    context 'with an indent size of 2' do
      before { @settings = {:indent_size => 2} }
      it "doesn't try to convert the 'end if foobar' technique" do
        @input = '  end if should_run_block?'
        @output = '  end if should_run_block?'
      end

      it "doesn't try to convert the 'end unless foobar' technique" do
        @input = '  end unless should_run_block?'
        @output = '  end unless should_run_block?'
      end

      it 'converts lines with guarded ifs into 3 liners' do
        @input = 'puts x if x > y && y.call'
        @output = "if x > y && y.call\n  puts x\nend"
      end

      it 'converts lines with guarded unlesses into 3 liners' do
        @input = 'puts x unless x > number'
        @output = "unless x > number\n  puts x\nend"
      end

      it 'converts lines with guarded ifs while maintaining indentation' do
        @input = '  puts x unless x > number'
        @output = "  unless x > number\n    puts x\n  end"
      end

      it 'only converts when it finds a guard on the top level expression' do
        @input = %Q[syms.each { |sym| raise ArgumentError, "unknown option '\#{sym}'" unless @specs[sym] }]
        @output = %Q[syms.each { |sym| raise ArgumentError, "unknown option '\#{sym}'" unless @specs[sym] }]
      end

      it 'only converts when it finds a guard on the real-world top level expression' do
        @input = 'x.select { |x| x if 5 }'
        @output = 'x.select { |x| x if 5 }'
      end

      it 'converts nested if/unless as guards' do
        @input = 'puts x if foo.bar unless baz.boo'
        @output = "unless baz.boo\n  if foo.bar\n    puts x\n  end\nend"
      end

      it 'converts nested three if/unless as guards' do
        @input = 'puts x if foo.bar unless baz.boo if alpha.beta'
        @output = "if alpha.beta\n  unless baz.boo\n    if foo.bar\n      puts x\n    end\n  end\nend"
      end

      it 'converts nested three if/unless as guards maintaining indentation' do
        @input = '    puts x if foo.bar unless baz.boo if alpha.beta'
        @output = "    if alpha.beta\n      unless baz.boo\n        if foo.bar\n          puts x\n        end\n      end\n    end"
      end
    end
  end
end

describe 'LineLengthMaximum' do
  before do
    @hundred_cap = LineLengthMaximum(100)
  end

  it 'matches lines longer than the specified maximum' do
    @hundred_cap.should warn('x' * 101)
  end

  it 'has a high severity' do
    @hundred_cap.severity.should >= 7.5
  end

  it 'does not match lines smaller than the specified maximum' do
    @hundred_cap.should_not warn('x' * 100)
  end
end

describe 'LineLengthWarning' do
  before do
    @hundred_cap = LineLengthWarning(80)
  end

  it 'matches lines longer than the specified maximum' do
    @hundred_cap.should warn('x' * 81)
  end

  it 'has a lower severity' do
    @hundred_cap.severity.should <= 4
  end

  it 'does not match lines smaller than the specified maximum' do
    @hundred_cap.should_not warn('x' * 80)
  end
end