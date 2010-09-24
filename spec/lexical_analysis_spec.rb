require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::LexicalAnalysis do
  before do
    @class = Class.new do
      include Wool::LexicalAnalysis
      attr_accessor :body
      def initialize(body)
        self.body = body
      end
    end
  end

  context '#lex' do
    it 'lexes its body' do
      @class.new('a').lex.should == [[[1,0], :on_ident, 'a']]
    end
  end

  context '#find_token' do
    it 'lexes its body' do
      @class.new('a + b').find_token(:on_op).should be_true
    end

    it 'returns falsy if token not found' do
      @class.new('a + b').find_token(:on_kw).should be_false
    end
    
    it 'works with multiple token options' do
      result = @class.new('a + b # hello').find_token(:on_op, :on_comment)
      result[1].should == :on_op
    end
  end

  context '#find_keyword' do
    it 'lexes its body' do
      @class.new('class A < B').find_keyword(:class).should be_true
    end

    it 'returns falsy if token not found' do
      @class.new('class A < B').find_keyword(:end).should be_false
    end

    it 'returns the actual token if it is found' do
      @class.new('class A < B').find_keyword(:class).should == [[1,0], :on_kw, 'class']
    end

    it 'works with multiple keyword options' do
      result = @class.new('class A < B; end').find_keyword(:class, :end)
      result[2].should == 'class'
    end
  end
end