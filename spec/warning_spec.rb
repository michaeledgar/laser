require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::Warning do
  context 'when subclassed' do
    it 'registers the new class in all_warnings' do
      klass = Class.new(Wool::Warning)
      Wool::Warning.all_warnings.should include(klass)
    end
  end

  it 'does not match anything' do
    Wool::Warning.match?('hello(world)', nil).should be_false
    Wool::Warning.match?(' a +b  ', nil).should be_false
  end

  it 'does not change lines when it fixes them' do
    warning = Wool::Warning.new('None', '(stdin)', 'a+b', 1, 0)
    warning.fix(nil).should == 'a+b'
    warning.body = ' b **   c+1 eval(string) '
    warning.fix(nil).should == ' b **   c+1 eval(string) '
  end

  context '#desc' do
    it "defaults to the class's name with all info" do
      Wool::Warning.new('temp', 'hello.rb', 'a+b', 3, 7).desc.should == 'Wool::Warning hello.rb:3 (7)'
    end
  end
end
