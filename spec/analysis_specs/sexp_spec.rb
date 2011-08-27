require_relative 'spec_helper'

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
  
  describe '#all_errors' do
    it 'should return all errors in the tree, in DFS order' do
      sexp = Sexp.new([[:abc], [:d, 2, [:e, 1]], [:def, [:a], [:b]]])
      sexp.errors = ['hi']
      sexp[0].errors = []
      sexp[1].errors = ['world']
      sexp[1][2].errors = ['another']
      sexp[2].errors = [2]
      sexp[2][1].errors = [3, 4]
      sexp[2][2].errors = [5, 6, 7]
      sexp.all_errors.should == ['hi', 'world', 'another', 2, 3, 4, 5, 6, 7]
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
  
  describe '#expanded_identifier' do
    ['abc', '@abc', 'ABC', '@@abc', '$abc'].each do |id|
      tree = Sexp.new(Ripper.sexp(id))
      actual_ident = tree[1][0][1]
      it "discovers expanded identifiers for simple identifiers of type #{actual_ident[0]}" do
        actual_ident.expanded_identifier.should == id
      end
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "abc", [1, 0]]],
    #    [:var_ref, [:@const, "ABC", [1, 6]]]]]]
    it 'handles var_ref and var_field nodes' do
      input = 'abc = ABC'
      tree = Sexp.new(Ripper.sexp(input))
      assign = tree[1][0]
      assign[1].expanded_identifier.should == 'abc'
      assign[2].expanded_identifier.should == 'ABC'
    end

    # [:program,
    # [[:assign,
    #   [:top_const_field, [:@const, "ABC", [1, 2]]],
    #   [:top_const_ref, [:@const, "DEF", [1, 10]]]]]]
    it 'handles top_const_ref and top_const_field nodes' do
      input = '::ABC = ::DEF'
      tree = Sexp.new(Ripper.sexp(input))
      assign = tree[1][0]
      assign[1].expanded_identifier.should == '::ABC'
      assign[2].expanded_identifier.should == '::DEF'
    end

    # [:program,
    #  [[:class,
    #    [:const_ref, [:@const, "ABC", [1, 6]]],
    #    nil,
    #    [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]
    it 'handles const_ref nodes (found in module/class declarations)' do
      input = 'class ABC; end'
      tree = Sexp.new(Ripper.sexp(input))
      klass = tree[1][0]
      klass[1].expanded_identifier.should == 'ABC'
    end

    # [:program,
    # [[:assign,
    #   [:top_const_field, [:@const, "ABC", [1, 2]]],
    #   [:top_const_ref, [:@const, "DEF", [1, 10]]]]]]
    it 'handles top_const_ref and top_const_field nodes' do
      input = '::ABC::DEF = ::DEF::XYZ'
      tree = Sexp.new(Ripper.sexp(input))
      assign = tree[1][0]
      assign[1].expanded_identifier.should == '::ABC::DEF'
      assign[2].expanded_identifier.should == '::DEF::XYZ'
    end
  end
end
