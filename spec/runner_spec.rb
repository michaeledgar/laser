require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::Runner do
  context '#swizzling_argv' do
    it 'changes ARGV to the runner\'s argv value' do
      Wool::Runner.new(['a', :b]).swizzling_argv do
        ARGV.should == ['a', :b]
      end
    end
  end
end
