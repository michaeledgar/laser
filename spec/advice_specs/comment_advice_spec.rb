require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Advice::CommentAdvice do
  before do
    @class = Class.new(Warning) do
      include Advice::CommentAdvice

      def match?(body = self.body, settings={})
        body
      end
      remove_comments
    end
  end

  context '#remove_comments' do
    it 'Returns the empty string unmodified' do
      @class.new('(stdin)', '').match?('').should == ''
    end

    it 'Turns a comment into the empty string' do
      @class.new('(stdin)', '# hello').match?('# hello').should == ''
    end

    it 'strips the comments from the end of a string of code' do
      @class.new('(stdin)', 'a + b # adding').match?('a + b # adding').should == 'a + b'
    end

    SAMPLES = [['', ''], ['#hello', ''], [' # hello', ''],
               [' a + b # hello', ' a + b'], ['(a + b) #', '(a + b)'],
               ['"#" + number', '"#" + number'],
               ['" hello \\"mam\\"" # comment', '" hello \\"mam\\""']]
    SAMPLES.each do |input, output|
      it "should turn #{input} into #{output}" do
        @class.new('(stdin)', input).match?(input).should == output
      end
    end
  end
end