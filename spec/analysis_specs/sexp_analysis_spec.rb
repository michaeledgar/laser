require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SexpAnalysis do
  describe Sexp do
    before do
      @sexp = Sexp.new([:if, [:abc, 2, 3], [:def, 4, 5], nil])
    end
    
    describe '#type' do
      it 'returns the type of the sexp' do
        @sexp.type.should == :if
        @sexp[1].type.should == :abc
        @sexp[2].type.should == :def
      end
    end
    
    describe '#children' do
      it 'returns the children of a normal sexp' do
        @sexp.children.should == [[:abc, 2, 3], [:def, 4, 5], nil]
        @sexp[1].children.should == [2, 3]
        @sexp[2].children.should == [4, 5]
      end
      
      it 'returns everything in an array if a whole-array sexp' do
        Sexp.new([[:abc], 2, 3, [:def, 3, 4]]).children.should == [[:abc], 2, 3, [:def, 3, 4]]
      end
    end
  end
  
  before do
    @class = Class.new do
      include SexpAnalysis
      attr_accessor :body
      def initialize(body)
        self.body = body
      end
    end
  end

  describe '#parse' do
    it 'parses its body' do
      @class.new('a').parse.should ==
          [:program, [[:var_ref, [:@ident, "a", [1, 0]]]]]
    end
  end

  describe '#find_sexps' do
    it 'searches its body' do
      @class.new('a + b').find_sexps(:binary).should_not be_empty
    end

    it 'returns an empty array if no sexps are found' do
      @class.new('a + b').find_sexps(:rescue).should be_empty
    end
  end
end