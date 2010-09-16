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
    it 'as a class method lexes its argument' do
      @class.lex('a').should == [[[1,0], :on_ident, 'a']]
    end

    it 'as an instance method lexes its body' do
      @class.new('a').lex.should == [[[1,0], :on_ident, 'a']]
    end
  end

  context '#has_token?' do
    it 'as a class method checks if the given text has the given token' do
      @class.has_token?('a + b', :on_op).should be_true
    end

    it 'as an instance method lexes its body' do
      @class.new('a + b').has_token?(:on_op).should be_true
    end

    it 'as a class method returns falsy if token not found' do
      @class.has_token?('a + b', :on_kw).should be_false
    end

    it 'as an instance method returns falsy if token not found' do
      @class.new('a + b').has_token?(:on_kw).should be_false
    end

    it 'returns the actual token if it is found' do
      @class.has_token?('a + b', :on_op).should == [[1,2], :on_op, '+']
    end
  end

  context '#has_keyword?' do
    it 'as a class method checks if the given text has the given keyword' do
      @class.has_keyword?('class A < B', 'class').should be_true
    end

    it 'as an instance method lexes its body' do
      @class.new('class A < B').has_keyword?('class').should be_true
    end

    it 'as a class method returns falsy if token not found' do
      @class.has_keyword?('class A < B', 'end').should be_false
    end

    it 'as an instance method returns falsy if token not found' do
      @class.new('class A < B').has_keyword?('end').should be_false
    end

    it 'returns the actual token if it is found' do
      @class.has_keyword?('class A < B', 'class').should == [[1,0], :on_kw, 'class']
    end
  end
end