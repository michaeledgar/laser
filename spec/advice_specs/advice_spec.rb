require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::Advice do
  context '#before_advice' do
    before do
      @class = Class.new do
        extend Wool::Advice
        attr_accessor :closed_over
        define_method :silly do
          self.closed_over ||= 1
          self.closed_over += 5
        end
        define_method :checkin do
          self.closed_over ||= 1
          self.closed_over *= 2
        end
        before_advice :silly, :checkin
      end
    end
    
    it 'causes the advised method to run the suggested advice before running' do
      @class.new.silly.should_not == 6
    end
    
    it 'causes the advice to run *before* the advised method' do
      @class.new.silly.should_not == 12
    end
  end
  
  context '#after_advice' do
    before do
      @class = Class.new do
        extend Wool::Advice
        attr_accessor :closed_over
        define_method :silly do
          self.closed_over ||= 1
          self.closed_over += 5
        end
        define_method :checkout do
          self.closed_over ||= 1
          self.closed_over *= 2
        end
        before_advice :silly, :checkout
      end
    end
    
    it 'causes the advised method to run the suggested advice after running' do
      @class.new.silly.should_not == 12
    end
    
    it 'causes the advice to run *after* the advised method' do
      @class.new.silly.should_not == 6
    end
  end
  
  context '#argument_advice' do
    before do
      @class = Class.new do
        extend Wool::Advice
        attr_accessor :closed_over
        define_method :silly do |arg|
          arg + 5
        end
        define_method :twiddle do |arg|
          arg * 2
        end
        argument_advice :silly, :twiddle
      end
    end
    
    it 'causes the advised method to run, rewriting the arguments' do
      @class.new.silly(1).should == 7
    end
  end
end
