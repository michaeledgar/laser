require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Warning do
  describe 'when subclassed' do
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
    Warning.should correct_to('a+b', 'a+b')
    Warning.should correct_to(' b **   c+1 eval(string) ', ' b **   c+1 eval(string) ')
  end

  describe '#concrete_warnings' do
    before { @concrete = Warning.concrete_warnings }
    it 'returns a list of classes that are subclasses of Warning' do
      @concrete.should_not be_empty
      @concrete.each {|w| w.ancestors.should include(Warning) }
    end
    
    it 'returns a list that does not contain Warning, FileWarning, or LineWarning' do
      @concrete.should_not include(Warning)
      @concrete.should_not include(FileWarning)
      @concrete.should_not include(LineWarning)
    end
  end

  describe '#desc' do
    it "defaults to the class's name with all info" do
      warning = Warning.new('hello.rb', 'a+b')
      warning.severity = 7
      warning.line_number = 3
      warning.desc.should == 'Laser::Warning hello.rb:3 (7)'
    end

    it 'when specified in a subclass as a string, just uses the string' do
      subclass = Class.new(Warning) { desc 'hello' }
      subclass.new('a', 'b').desc.should == 'hello'
    end

    it 'when specified in a subclass as a block, runs that proc as the instance' do
      subclass = Class.new(Warning) do
        severity 1024
        desc { self.class.severity.to_s }
      end
      subclass.new('a', 'b').desc.should == '1024'
    end
  end

  describe '#type' do
    it 'returns the current type when no args are provided' do
      klass = Class.new(Warning) do
        def self.set_type
          @type = 'hai'
        end
      end
      klass.set_type
      klass.type.should == 'hai'
    end

    it 'sets the type when an argument is provided' do
      klass = Class.new(Warning) { type :silly }
      klass.type.should == 'silly'
    end

    it 'sets a short name based on the type provided' do
      klass = Class.new(Warning) { type :silly }
      klass.short_name.should =~ /SI\d/
    end
  end
end