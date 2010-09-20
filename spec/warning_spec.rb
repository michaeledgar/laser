require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Warning do
  context 'when subclassed' do
    it 'registers the new class in all_warnings' do
      klass = Class.new(Warning)
      Warning.all_warnings.should include(klass)
    end
  end

  it 'does not match anything' do
    Warning.should_not warn('hello(world)')
    Warning.should_not warn(' a +b  ')
  end

  describe 'short names in warnings' do
    before do
      @real_warnings = Warning.all_warnings.select do |x|
        x.name && x != Warning && x != FileWarning && x != LineWarning
      end
    end
    
    it 'exist for every warning class' do
      @real_warnings.select {|x| x.name && x.short_name == nil}.should be_empty
    end
    
    it 'do not conflict with each other' do
      short_names = @real_warnings.map {|x| x.short_name}.uniq
      short_names.size.should == @real_warnings.size
    end
  end

  it 'does not change lines when it fixes them' do
    warning = Warning.new('None', '(stdin)', 'a+b', 1, 0)
    warning.fix(nil).should == 'a+b'
    warning.body = ' b **   c+1 eval(string) '
    warning.fix(nil).should == ' b **   c+1 eval(string) '
  end

  context '#desc' do
    it "defaults to the class's name with all info" do
      Warning.new('temp', 'hello.rb', 'a+b', 3, 7).desc.should ==
          'Wool::Warning hello.rb:3 (7)'
    end
  end

  context '#split_on_char_outside_literal' do
    def splitted(input, match)
      Warning.new.split_on_char_outside_literal(input, match)
    end

    it 'splits code and a comment with no literals present' do
      splitted('hello world # runs hello', /#/).should ==
          ['hello world ', '# runs hello']
    end

    it 'ignores the character when in a single-quote literal' do
      splitted("hello 'world # runs' hello", /#/).should ==
          ["hello 'world # runs' hello", '']
    end

    it 'can handle code with double nesting' do
      input = %{Warning.new.split_on_char_outside_literal("hello 'world # runs' hello", /#/).should}
      output = [input, '']
      splitted(input, /#/).should == output
    end

    it 'ignores the character when in a double-quote literal' do
      splitted('hello "world # runs" hello', /#/).should ==
          ['hello "world # runs" hello', '']
    end

    it 'ignores the character when in a regex literal' do
      splitted('hello /world # runs/ hello', /#/).should ==
          ['hello /world # runs/ hello', '']
    end

    it 'catches the character even with escaped quotes in literals' do
      splitted('"hello \"world\"" # runs hello', /#/).should ==
          ['"hello \"world\"" ', '# runs hello']
    end

    it 'ignores embedded values in single quote strings in double quote strings' do
      input = %Q{"my message is: 'hello, \#{name}', i hope he likes it"}
      output = [input, '']
      splitted(input, /#/).should == output
    end

    it 'works for multichar regex matches' do
      input = ' puts x.call(y) if x > y'
      output = [' puts x.call(y)', ' if x > y']
      splitted(input, /(\b|\s)if\b/).should == output
    end
  end
end