require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe LexicalAnalysis do
  before do
    @class = Class.new do
      include LexicalAnalysis
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
    
    it 'is not triggered by symbols' do
      @class.new(':+').find_token(:on_op).should be_false
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

    it 'is not triggered by symbols' do
      @class.new(':unless').find_keyword(:unless).should be_false
    end
  end

  context '#split_on_token' do
    it 'splits the input into two parts based on the token searched' do
      left, right = @class.new('a + b; c + d').split_on_token(:on_semicolon)
      left.should == 'a + b'
      right.should == '; c + d'
    end

    it 'works with multiple searched tokens' do
      left, right = @class.new('a + b; c + d').split_on_token(:on_semicolon, :on_op)
      left.should == 'a '
      right.should == '+ b; c + d'
    end

    it 'matches its own documentation' do
      left, right = @class.new('').split_on_token('x = 5 unless y == 2', :on_kw)
      left.should == 'x = 5 '
      right.should == 'unless y == 2'
    end
  end


  context '#split_on_keyword' do
    it 'splits the input into two parts based on the token searched' do
      left, right = @class.new('rescue x if y').split_on_keyword(:if)
      left.should == 'rescue x '
      right.should == 'if y'
    end

    it 'works with multiple searched tokens' do
      left, right = @class.new('rescue x if y').split_on_keyword(:if, :rescue)
      left.should == ''
      right.should == 'rescue x if y'
    end

    it 'matches its own documentation' do
      left, right = @class.new('').split_on_keyword('x = 5 unless y == 2', :unless)
      left.should == 'x = 5 '
      right.should == 'unless y == 2'
    end
  end
end