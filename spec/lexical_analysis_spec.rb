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
    it 'as an instance method lexes its body' do
      @class.new('a').lex.should == [[[1,0], :on_ident, 'a']]
    end
  end

  context '#find_token' do
    it 'as an instance method lexes its body' do
      @class.new('a + b').find_token(:on_op).should be_true
    end

    it 'as an instance method returns falsy if token not found' do
      @class.new('a + b').find_token(:on_kw).should be_false
    end
  end

  context '#find_keyword' do
    it 'as an instance method lexes its body' do
      @class.new('class A < B').find_keyword('class').should be_true
    end

    it 'as an instance method returns falsy if token not found' do
      @class.new('class A < B').find_keyword('end').should be_false
    end

    it 'returns the actual token if it is found' do
      @class.new('class A < B').find_keyword('class').should == [[1,0], :on_kw, 'class']
    end
  end
end