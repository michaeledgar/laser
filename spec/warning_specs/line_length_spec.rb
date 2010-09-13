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

    it 'takes a line with just a comment on it and breaks it into many lines' do
      input = '# my comment is this and that and another thing'
      output = "# my comment is this\n# and that and\n# another thing"
      @twenty_cap.new('(stdin)', input).fix.should == output
    end

    it 'creates new lines with the same indentation as the input' do
      input = '   # my comment is this and that and another thing'
      output = "   # my comment is\n   # this and that\n   # and another\n   # thing"
      @twenty_cap.new('(stdin)', input).fix.should == output
    end

    it 'uses the same number of hashes to denote the comment' do
      input = ' ## my comment is this and that and another thing'
      output = " ## my comment is\n ## this and that\n ## and another\n ## thing"
      @twenty_cap.new('(stdin)', input).fix.should == output
    end

    it 'splits up code with an overly long comment at the end' do
      input = '  a + b # this is a stupidly long comment lol'
      output = "  # this is a\n  # stupidly long\n  # comment lol\n  a + b"
      @twenty_cap.new('(stdin)', input).fix.should == output
    end

    it 'uses the same indentation and hashes for the new comment' do
      input = ' a + b ### this is a stupidly long comment lol'
      output = " ### this is a\n ### stupidly long\n ### comment lol\n a + b"
      @twenty_cap.new('(stdin)', input).fix.should == output
    end
    
    it "doesn't try to convert the 'end if foobar' technique" do
      input = '  end if should_run_block?'
      output = '  end if should_run_block?'
      @twenty_cap.new('(stdin)', input, :indent_size => 2).fix.should == output
    end
    
    it "doesn't try to convert the 'end unless foobar' technique" do
      input = '  end unless should_run_block?'
      output = '  end unless should_run_block?'
      @twenty_cap.new('(stdin)', input, :indent_size => 2).fix.should == output
    end
    
    it 'converts lines with guarded ifs into 3 liners' do
      input = 'puts x if x > y && y.call'
      output = "if x > y && y.call\n  puts x\nend"
      @twenty_cap.new('(stdin)', input, :indent_size => 2).fix.should == output
    end
    
    it 'converts lines with guarded unlesses into 3 liners' do
      input = 'puts x unless x > number'
      output = "unless x > number\n  puts x\nend"
      @twenty_cap.new('(stdin)', input, :indent_size => 2).fix.should == output
    end
    
    it 'converts lines with guarded ifs while maintaining indentation' do
      input = '  puts x unless x > number'
      output = "  unless x > number\n    puts x\n  end"
      @twenty_cap.new('(stdin)', input, :indent_size => 2).fix.should == output
    end

    it 'only converts when it finds a guard on the top level expression' do
      input = %Q[syms.each { |sym| raise ArgumentError, "unknown option '\#{sym}'" unless @specs[sym] }]
      output = %Q[syms.each { |sym| raise ArgumentError, "unknown option '\#{sym}'" unless @specs[sym] }]
      @twenty_cap.new('(stdin)', input, :indent_size => 2).fix.should == output
    end
    
    it 'only converts when it finds a guard on the real-world top level expression' do
      input = 'x.select { |x| x if 5 }'
      output = 'x.select { |x| x if 5 }'
      @twenty_cap.new('(stdin)', input, :indent_size => 2).fix.should == output
    end
    
    it 'converts nested if/unless as guards' do
      input = 'puts x if foo.bar unless baz.boo'
      output = "unless baz.boo\n  if foo.bar\n    puts x\n  end\nend"
      @twenty_cap.new('(stdin)', input, :indent_size => 2).fix.should == output
    end
    
    it 'converts nested three if/unless as guards' do
      input = 'puts x if foo.bar unless baz.boo if alpha.beta'
      output = "if alpha.beta\n  unless baz.boo\n    if foo.bar\n      puts x\n    end\n  end\nend"
      @twenty_cap.new('(stdin)', input, :indent_size => 2).fix.should == output
    end
    
    it 'converts nested three if/unless as guards maintaining indentation' do
      input = '    puts x if foo.bar unless baz.boo if alpha.beta'
      output = "    if alpha.beta\n      unless baz.boo\n        if foo.bar\n          puts x\n        end\n      end\n    end"
      @twenty_cap.new('(stdin)', input, :indent_size => 2).fix.should == output
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