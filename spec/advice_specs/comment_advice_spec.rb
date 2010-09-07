require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::Advice::CommentAdvice do
  before do
    @class = Class.new(Wool::Warning) do
      extend Wool::Advice::CommentAdvice

      def self.match?(body, context)
        body
      end
      remove_comments
    end
  end
  
  context '#remove_comments' do
    it 'Returns the empty string unmodified' do
      @class.match?('', nil).should == ''
    end
    
    it 'Turns a comment into the empty string' do
      @class.match?('# hello', nil).should == ''
    end
    
    it 'strips the comments from the end of a string of code' do
      @class.match?('a + b # adding', nil).should == 'a + b'
    end
    
    SAMPLES = [['', ''], ['#hello', ''], [' # hello', ''],
               [' a + b # hello', ' a + b'], ['(a + b) #', '(a + b)'],
               ['"#" + number', '"#" + number'],
               ['" hello \\"mam\\"" # comment', '" hello \\"mam\\""']]
    SAMPLES.each do |input, output|
      it "should turn #{input} into #{output}" do
        @class.match?(input, nil).should == output
      end
    end
  end
end
