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

  context '#text_between_token_positions' do
    it 'finds the exclusive text between two simple tokens from a body text' do
      body = "def initialize(body)\n    self.body = body\nend"
      left = [[2, 4], :on_kw, "self"]
      right = [[2, 20], :on_nl, "\n"]
      @class.new('').text_between_token_positions(body, left, right).should ==
          '.body = body'
    end
    
    it 'allows including the left token with the inclusive :left hash option' do
      body = "def initialize(body)\n    self.body = body\nend"
      left = [[2, 4], :on_kw, "self"]
      right = [[2, 20], :on_nl, "\n"]
      @class.new('').text_between_token_positions(body, left, right, :left).should ==
          'self.body = body'
    end
    
    it 'allows including the right token with the inclusive :right hash option' do
      body = "def initialize(body)\n    self.body = body\nend"
      left = [[2, 4], :on_kw, "self"]
      right = [[2, 20], :on_nl, "\n"]
      @class.new('').text_between_token_positions(body, left, right, :right).should ==
          ".body = body\n"
    end
    
    it 'allows including both tokens with the inclusive :both hash option' do
      body = "def initialize(body)\n    self.body = body\nend"
      left = [[2, 4], :on_kw, "self"]
      right = [[2, 20], :on_nl, "\n"]
      @class.new('').text_between_token_positions(body, left, right, :both).should ==
          "self.body = body\n"
    end
        
    it 'allows explicitly to exclude the tokens with the inclusive :none option' do
      body = "def initialize(body)\n    self.body = body\nend"
      left = [[2, 4], :on_kw, "self"]
      right = [[2, 20], :on_nl, "\n"]
      @class.new('').text_between_token_positions(body, left, right, :none).should ==
          '.body = body'
    end
    
    context 'spanning multiple lines' do
      it 'allows including the left token with the inclusive :left hash option' do
        body = "def initialize(body)\n    self.body = body\nend # a * b"
        left = [[1, 14], :on_lparen, "("]
        right = [[3, 3], :on_sp, " "]
        @class.new('').text_between_token_positions(body, left, right, :left).should ==
            "(body)\n    self.body = body\nend"
      end
          
      it 'allows including the right token with the inclusive :right hash option' do
        body = "def initialize(body)\n    self.body = body\nend # a * b"
        left = [[1, 14], :on_lparen, "("]
        right = [[3, 3], :on_sp, " "]
        @class.new('').text_between_token_positions(body, left, right, :right).should ==
            "body)\n    self.body = body\nend "
      end
          
      it 'allows including both tokens with the inclusive :both hash option' do
        body = "def initialize(body)\n    self.body = body\nend # a * b"
        left = [[1, 14], :on_lparen, "("]
        right = [[3, 3], :on_sp, " "]
        @class.new('').text_between_token_positions(body, left, right, :both).should ==
            "(body)\n    self.body = body\nend "
      end
          
      it 'allows explicitly to exclude the tokens with the inclusive :none option' do
        body = "def initialize(body)\n    self.body = body\nend # a * b"
        left = [[1, 14], :on_lparen, "("]
        right = [[3, 3], :on_sp, " "]
        @class.new('').text_between_token_positions(body, left, right, :none).should ==
            "body)\n    self.body = body\nend"
      end
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