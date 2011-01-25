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
    
    describe 'performing DFS operations' do
      before do
        @hard_sexp = Sexp.new([:program,
                     [[:class,
                       [:const_ref, [:@const, "A", [1, 6]]],
                       [:var_ref, [:@const, "String", [1, 10]]],
                       [:bodystmt,
                        [[:defs,
                          [:var_ref, [:@kw, "self", [1, 22]]],
                          [:@period, ".", [1, 26]],
                          [:@ident, "silly", [1, 27]],
                          [:paren,
                           [:params,
                            [[:@ident, "x", [1, 33]]], nil,
                            [:rest_param, [:@ident, "y", [1, 37]]], nil, nil]],
                          [:bodystmt,
                           [[:void_stmt],
                            [:massign,
                             [:mlhs_paren, [[:@ident, "x", [1, 42]], [:@ident, "y", [1, 45]]]],
                             [:mrhs_add_star, [], [:var_ref, [:@ident, "y", [1, 51]]]]]],
                           nil, nil, nil]]],
                        nil, nil, nil]]]])
        # While I had to manually figure this out, a simple look at the indices used
        # shows that it is a proper DFS order.
        @correct_order = [@hard_sexp,
                          @hard_sexp[1][0],
                          @hard_sexp[1][0][1],
                          @hard_sexp[1][0][1][1],
                          @hard_sexp[1][0][2],
                          @hard_sexp[1][0][2][1],
                          @hard_sexp[1][0][3],
                          @hard_sexp[1][0][3][1][0],
                          @hard_sexp[1][0][3][1][0][1],
                          @hard_sexp[1][0][3][1][0][1][1],
                          @hard_sexp[1][0][3][1][0][2],
                          @hard_sexp[1][0][3][1][0][3],
                          @hard_sexp[1][0][3][1][0][4],
                          @hard_sexp[1][0][3][1][0][4][1],
                          @hard_sexp[1][0][3][1][0][4][1][1][0],
                          @hard_sexp[1][0][3][1][0][4][1][3],
                          @hard_sexp[1][0][3][1][0][4][1][3][1],
                          @hard_sexp[1][0][3][1][0][5],
                          @hard_sexp[1][0][3][1][0][5][1][0],
                          @hard_sexp[1][0][3][1][0][5][1][1],
                          @hard_sexp[1][0][3][1][0][5][1][1][1],
                          @hard_sexp[1][0][3][1][0][5][1][1][1][1][0],
                          @hard_sexp[1][0][3][1][0][5][1][1][1][1][1],
                          @hard_sexp[1][0][3][1][0][5][1][1][2],
                          @hard_sexp[1][0][3][1][0][5][1][1][2][2],
                          @hard_sexp[1][0][3][1][0][5][1][1][2][2][1]]
      end
      describe '#dfs' do
        # this test sucked to write.
        it 'yields the nodes of the tree in DFS order' do
          result = []
          @hard_sexp.dfs { |node| result << node }
          result.should == @correct_order
        end
      end
    
      describe '#dfs_enumerator' do
        it 'should enumerate every element in DFS order' do
          enumerator = @hard_sexp.dfs_enumerator
          enumerator.entries.should == @correct_order
        end
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