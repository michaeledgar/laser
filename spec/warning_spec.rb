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

  context '#type' do
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
      klass = Class.new(Warning) do
        type :silly
      end
      klass.type.should == 'silly'
    end
    
    it 'sets a short name based on the type provided' do
      klass = Class.new(Warning) do
        type :silly
      end
      klass.short_name.should =~ /SI\d/
    end
  end
end