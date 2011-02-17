require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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
  
  describe '#expr_type' do
    # This is the AST that Ripper generates for the parsed code. It is
    # provided here because otherwise the test is inscrutable.
    #
    # [:program,
    # [[:assign,
    #    [:var_field, [:@ident, "a", [1, 0]]], [:@int, "5", [1, 4]]]]]
    it 'discovers the class for integer literals' do
      tree = Sexp.new(Ripper.sexp('a = 5'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('Integer', :covariant)
    end

    # This is the AST that Ripper generates for the parsed code. It is
    # provided here because otherwise the test is inscrutable.
    #
    # [:program,
    # [[:assign,
    #   [:var_field, [:@ident, "a", [1, 0]]],
    #   [:string_literal,
    #    [:string_content,
    #     [:@tstring_content, "abc = ", [1, 5]],
    #     [:string_embexpr,
    #      [[:binary,
    #        [:var_ref, [:@ident, "run_method", [1, 13]]],
    #        :-,
    #        [:@int, "5", [1, 26]]]]]]]]]]
    it 'discovers the class for nontrivial string literals' do
      tree = Sexp.new(Ripper.sexp('a = "abc = #{run_method - 5}"'))
      list = tree[1]
      [list[0][2], list[0][2][1], list[0][2][1][1], list[0][2][1][2]].each do |entry|
        entry.expr_type.should == Types::ClassType.new('String', :invariant)
      end
    end

    # [:program,
    # [[:assign,
    #   [:var_field, [:@ident, "a", [1, 0]]],
    #   [:xstring_literal, [[:@tstring_content, "find .", [1, 7]]]]]]]
    it 'discovers the class for executed string literals' do
      tree = Sexp.new(Ripper.sexp('a = %x(find .)'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('String', :invariant)
    end

    # [:program,
    #  [[:assign,
    #     [:var_field, [:@ident, "a", [1, 0]]],
    #     [:@CHAR, "?a", [1, 4]]]]]
    it 'discovers the class for character literals' do
      tree = Sexp.new(Ripper.sexp('a = ?a'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('String', :invariant)
    end

    # [:program,
    # [[:assign,
    #    [:var_field, [:@ident, "x", [1, 0]]],
    #    [:@float, "3.14", [1, 4]]]]]
    it 'discovers the class for float literals' do
      tree = Sexp.new(Ripper.sexp('x = 3.14'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('Float', :invariant)
    end

    # [:program,
    # [[:assign,
    #   [:var_field, [:@ident, "x", [1, 0]]],
    #   [:regexp_literal,
    #    [[:@tstring_content, "abc", [1, 5]]],
    #    [:@regexp_end, "/im", [1, 8]]]]]]
    it 'discovers the class for regexp literals' do
      tree = Sexp.new(Ripper.sexp('x = /abc/im'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('Regexp', :invariant)
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "x", [1, 0]]],
    #    [:array, [[:@int, "1", [1, 5]], [:@int, "2", [1, 8]]]]]]]
    it 'discovers the class for array literals' do
      tree = Sexp.new(Ripper.sexp('x = [1, 2]'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('Array', :invariant)
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "x", [1, 0]]],
    #    [:hash,
    #     [:assoclist_from_args,
    #      [[:assoc_new,
    #        [:@label, "a:", [1, 5]],
    #        [:symbol_literal, [:symbol, [:@ident, "b", [1, 9]]]]]]]]]]]
    it 'discovers the class for hash literals' do
      tree = Sexp.new(Ripper.sexp('x = {a: :b}'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('Hash', :invariant)
    end

    # [:program,
    #  [[:method_add_arg,
    #    [:fcall, [:@ident, "p", [1, 0]]],
    #    [:arg_paren,
    #     [:args_add_block,
    #      [[:bare_assoc_hash,
    #        [[:assoc_new, [:@label, "a:", [1, 2]], [:@int, "3", [1, 5]]],
    #         [:assoc_new, [:@label, "b:", [1, 8]], [:@int, "3", [1, 11]]]]]],
    #      false]]]]]
    it 'discovers the class for hash literals using the no-brace shorthand' do
      tree = Sexp.new(Ripper.sexp('p(a: 3, b: 3)'))
      list = tree[1]
      list[0][2][1][1][0].expr_type.should == Types::ClassType.new('Hash', :invariant)
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "x", [1, 0]]],
    #    [:symbol_literal, [:symbol, [:@ident, "abcdef", [1, 5]]]]]]]
    it 'discovers the class for symbol literals' do
      tree = Sexp.new(Ripper.sexp('x = :abcdef'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('Symbol', :invariant)
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "x", [1, 0]]],
    #    [:dyna_symbol,
    #     [[:@tstring_content, "abc", [1, 6]],
    #      [:string_embexpr, [[:var_ref, [:@ident, "xyz", [1, 11]]]]],
    #      [:@tstring_content, "def", [1, 15]]]]]]]
    it 'discovers the class for dynamic symbol literals' do
      tree = Sexp.new(Ripper.sexp('x = :"abc{xyz}def"'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('Symbol', :invariant)
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "x", [1, 0]]],
    #    [:hash,
    #     [:assoclist_from_args,
    #      [[:assoc_new,
    #        [:@label, "a:", [1, 5]],
    #        [:symbol_literal, [:symbol, [:@ident, "b", [1, 9]]]]]]]]]]]
    it 'discovers the class for the label-style symbols in Ruby 1.9' do
      tree = Sexp.new(Ripper.sexp('x = {a: :b}'))
      list = tree[1]
      list[0][2][1][1][0][1].expr_type.should == Types::ClassType.new('Symbol', :invariant)
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "x", [1, 0]]],
    #    [:var_ref, [:@kw, "true", [1, 4]]]]]]
    it 'discovers the class for true' do
      tree = Sexp.new(Ripper.sexp('x = true'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('TrueClass', :invariant)
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "x", [1, 0]]],
    #    [:var_ref, [:@kw, "false", [1, 4]]]]]]
    it 'discovers the class for false' do
      tree = Sexp.new(Ripper.sexp('x = false'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('FalseClass', :invariant)
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "x", [1, 0]]],
    #    [:var_ref, [:@kw, "nil", [1, 4]]]]]]
    it 'discovers the class for nil' do
      tree = Sexp.new(Ripper.sexp('x = nil'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('NilClass', :invariant)
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "x", [1, 0]]],
    #    [:var_ref, [:@kw, "__FILE__", [1, 4]]]]]]
    it 'discovers the class for __FILE__' do
      tree = Sexp.new(Ripper.sexp('x = __FILE__'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('String', :invariant)
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "x", [1, 0]]],
    #    [:var_ref, [:@kw, "__LINE__", [1, 4]]]]]]
    it 'discovers the class for __LINE__' do
      tree = Sexp.new(Ripper.sexp('x = __LINE__'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('Fixnum', :invariant)
    end


    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "x", [1, 0]]],
    #    [:var_ref, [:@kw, "__LINE__", [1, 4]]]]]]
    it 'discovers the class for __ENCODING__' do
      tree = Sexp.new(Ripper.sexp('x = __ENCODING__'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('Encoding', :invariant)
    end


    # [:program,
    # [[:assign,
    #   [:var_field, [:@ident, "x", [1, 0]]],
    #   [:dot2, [:@int, "2", [1, 4]], [:@int, "9", [1, 7]]]]]]
    it 'discovers the class for inclusive ranges' do
      tree = Sexp.new(Ripper.sexp('x = 2..9'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('Range', :invariant)
    end


    # [:program,
    # [[:assign,
    #   [:var_field, [:@ident, "x", [1, 0]]],
    #   [:dot3, [:@int, "2", [1, 4]], [:@int, "9", [1, 8]]]]]]
    it 'discovers the class for exclusive ranges' do
      tree = Sexp.new(Ripper.sexp('x = 2...9'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('Range', :invariant)
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "x", [1, 0]]],
    #    [:lambda,
    #     [:paren, [:params, [[:@ident, "a", [1, 7]]], nil, nil, nil, nil]],
    #     [[:var_ref, [:@ident, "a", [1, 10]]]]]]]]
    it "discovers the class for 1.9's stabby lambdas" do
      tree = Sexp.new(Ripper.sexp('x = ->(a, b=2){ a + b }'))
      list = tree[1]
      list[0][2].expr_type.should == Types::ClassType.new('Proc', :invariant)
    end
  end
  
  describe '#constant_value' do
    
    it 'defaults to assigning is_constant=false, constant_value=:none' do
      tree = Sexp.new(Ripper.sexp('a'))
      list = tree[1]
      list[0][1].is_constant.should be false
      list[0][1].constant_value.should be :none
    end

    describe 'keyword literals' do
      it 'should resolve nil' do
        tree = Sexp.new(Ripper.sexp('a = nil'))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == nil
      end
      
      it 'should resolve true' do
        tree = Sexp.new(Ripper.sexp('a = true'))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == true
      end
      
      it 'should resolve false' do
        tree = Sexp.new(Ripper.sexp('a = false'))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == false
      end
      
      it 'should resolve __LINE__' do
        tree = Sexp.new(Ripper.sexp("a = \n__LINE__"))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == 2
      end
      
      it 'should resolve __FILE__' do
        tree = Sexp.new(Ripper.sexp("a = \n__FILE__"), 'abc/def.rb', "a = \n__FILE__")
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == 'abc/def.rb'
      end
    end

    describe 'character literals' do
      it 'works with single-char literals' do
        tree = Sexp.new(Ripper.sexp('a = ?X'))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == 'X'
      end

      it 'works with oddball char literals' do
        tree = Sexp.new(Ripper.sexp('a = ?\M-\C-a'))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == "\x81"
      end
    end

    describe 'handling string literals' do
      it 'should interpret simple strings' do
        input = 'a = "abc def"'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == "abc def"
      end

      it 'should give up with complex interpolation' do
        input = 'a = "abc #{foobar()} def"'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be false
      end

      it 'should handle embedded escapes' do
        input = 'a = "abc \n \x12def"'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == "abc \n \x12def"
      end

      it 'should not evaluate embedded escapes for single-quoted strings' do
        input = %q{a = 'abc \n \x12def'}
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == 'abc \n \x12def'
      end
    end

    describe 'handling integer literals' do
      it 'discovers the constant value for small decimal literals' do
        tree = Sexp.new(Ripper.sexp('a = 5'))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == 5
      end

      it 'discovers the constant value for huge integer literals' do
        tree = Sexp.new(Ripper.sexp('a = 5123907821349078'))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == 5123907821349078
      end

      it 'discovers the constant value for hex integer literals' do
        tree = Sexp.new(Ripper.sexp('a = 0xabde3456'))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == 0xabde3456
      end

      it 'discovers the constant value for octal integer literals' do
        tree = Sexp.new(Ripper.sexp('a = 012343222245566'))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == 012343222245566
      end

      it 'discovers the constant value for binary integer literals' do
        tree = Sexp.new(Ripper.sexp('a = 0b10100011101010110001'))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == 0b10100011101010110001
      end
    end

    describe 'handling float literals' do
      it 'discovers the constant value for small decimal literals' do
        tree = Sexp.new(Ripper.sexp('a = 5.124897e3'))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == 5.124897e3
      end
    end

    describe 'symbol literals' do
      [:abc_def, :ABC_DEF, :@abc_def, :$abc_def, :@@abc_def, :"hello-world"].each do |sym|
        it "should convert simple symbols of the form #{sym.inspect}" do
          input = "a = #{sym.inspect}"
          tree = Sexp.new(Ripper.sexp(input))
          list = tree[1]
          list[0][2].is_constant.should be true
          list[0][2].constant_value.should == sym
        end
      end

      # [:program,
      #  [[:hash,
      #    [:assoclist_from_args,
      #     [[:assoc_new,
      #       [:@label, "abc:", [1, 1]],
      #       [:symbol_literal, [:symbol, [:@kw, "def", [1, 7]]]]]]]]]]
      it 'can discover the value of labels in 1.9 hash syntax' do
        input = '{abc: :def}'
        tree = Sexp.new(Ripper.sexp(input))
        label = tree[1][0][1][1][0][1]
        label.is_constant.should be true
        label.constant_value.should == :abc
      end
    end

    describe 'inclusive range literals' do
      it 'calculates a constant if both ends of the range are constants' do
        tree = Sexp.new(Ripper.sexp('a = 2..0x33'))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == (2..51)
      end

      it 'does not create a constant if one of the ends is not a constant' do
        tree = Sexp.new(Ripper.sexp('a = 2..(foobar(2))'))
        list = tree[1]
        list[0][2].is_constant.should be false
      end
    end

    describe 'exclusive range literals' do
      it 'calculates a constant if both ends of the range are constants' do
        tree = Sexp.new(Ripper.sexp('a = 2...0x33'))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == (2...51)
      end

      it 'does not create a constant if one of the ends is not a constant' do
        tree = Sexp.new(Ripper.sexp('a = 2...(foobar(2))'))
        list = tree[1]
        list[0][2].is_constant.should be false
      end
    end

    describe 'regex literals' do
      it 'interprets a simple constant regex with standard syntax' do
        input = 'a = /abcdef/'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == /abcdef/
      end

      it 'does not try to fold complex interpolated regexps' do
        input = 'a = /abc#{abc()}def/'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be false
      end

      it 'interprets a simple regex with nonstandard syntax and options' do
        input = 'a = %r|abcdef|im'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == /abcdef/im
      end

      it 'interprets a simple regex with extended mode' do
        input = 'a = %r|abcdef|x'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == /abcdef/x
      end
    end

    describe 'array literals' do
      it 'can evaluate empty hashes' do
        input = 'a =  [ ]'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == []
      end

      it 'should find the constant value if all members are constant' do
        input = 'a = [:a, 3.14, "hello", /abc/x]'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == [:a, 3.14, "hello", /abc/x]
      end

      it 'should not calculate a constant if a member is not a constant' do
        input = 'a = [:a, :"hi-there", 3.14, foobar()]'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be false
      end
    end

    describe 'hash literals' do
      it 'can evaluate empty hashes' do
        input = 'a = {}'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == {}
      end

      it 'can evaluate simple constant hashes' do
        input = 'a = {:a => :b, 3 => 2, "hi" => "world", :a => :c}'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == {:a => :c, 3 => 2, "hi" => "world"}
      end

      it 'gives up on obviously non-constant hashes' do
        input = 'a = {foobar() => baz()}'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be false
      end

      it 'can evaluate constant, bare hashes' do
        input = 'a = foo(:a => :b, 3 => 2, "hi" => "world", :a => :c)'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2][2][1][1][0].is_constant.should be true
        list[0][2][2][1][1][0].constant_value.should == {:a => :c, 3 => 2, "hi" => "world"}
      end
    end

    describe 'stuff in parentheses' do
      it 'can handle a range in parens' do
        input = 'a = ("a".."z")'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == ("a".."z")
      end

      it 'can handle compound expressions in parens, taking the value of the last constant' do
        input = 'a = (3; 2; "a".."z")'
        tree = Sexp.new(Ripper.sexp(input))
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == ("a".."z")
      end
    end
  end
end