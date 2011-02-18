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
        tree = annotate_all(input)
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == "abc def"
      end

      it 'should give up with complex interpolation' do
        input = 'a = "abc #{foobar()} def"'
        tree = annotate_all(input)
        list = tree[1]
        list[0][2].is_constant.should be false
      end

      it 'should handle embedded escapes' do
        input = 'a = "abc \n \x12def"'
        tree = annotate_all(input)
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == "abc \n \x12def"
      end

      it 'should not evaluate embedded escapes for single-quoted strings' do
        input = %q{a = 'abc \n \x12def'}
        tree = annotate_all(input)
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
          tree = annotate_all(input)
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
        tree = annotate_all(input)
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == /abcdef/
      end

      it 'does not try to fold complex interpolated regexps' do
        input = 'a = /abc#{abc()}def/'
        tree = annotate_all(input)
        list = tree[1]
        list[0][2].is_constant.should be false
      end

      it 'interprets a simple regex with nonstandard syntax and options' do
        input = 'a = %r|abcdef|im'
        tree = annotate_all(input)
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == /abcdef/im
      end

      it 'interprets a simple regex with extended mode' do
        input = 'a = %r|abcdef|x'
        tree = annotate_all(input)
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
        tree = annotate_all(input)
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == [:a, 3.14, "hello", /abc/x]
      end

      it 'should not calculate a constant if a member is not a constant' do
        input = 'a = [:a, :"hi-there", 3.14, foobar()]'
        tree = annotate_all(input)
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
        tree = annotate_all(input)
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
        tree = annotate_all(input)
        list = tree[1]
        list[0][2][2][1][1][0].is_constant.should be true
        list[0][2][2][1][1][0].constant_value.should == {:a => :c, 3 => 2, "hi" => "world"}
      end
    end

    describe 'stuff in parentheses' do
      it 'can handle a range in parens' do
        input = 'a = ("a".."z")'
        tree = annotate_all(input)
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == ("a".."z")
      end

      it 'can handle compound expressions in parens, taking the value of the last constant' do
        input = 'a = (3; 2; "a".."z")'
        tree = annotate_all(input)
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == ("a".."z")
      end
    end
  end
  
  describe '#source_begin/#source_end' do
    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "arr", [1, 0]]],
    #    [:mrhs_new_from_args,
    #     [[:var_ref, [:@kw, "true", [1, 6]]],
    #      [:var_ref, [:@kw, "nil", [1, 12]]],
    #      [:@int, "314", [1, 17]],
    #      [:@float, "4.155", [1, 22]],
    #      [:@CHAR, "?x", [1, 29]],
    #      [:regexp_literal,
    #       [[:@tstring_content, "ac", [1, 34]]],
    #       [:@regexp_end, "/ix", [1, 36]]],
    #      [:string_literal,
    #       [:string_content,
    #        [:@tstring_content, "Abc", [1, 42]],
    #        [:string_embexpr, [[:var_ref, [:@ident, "hi", [1, 47]]]]]]],
    #      [:dyna_symbol,
    #       [[:@tstring_content, "hello ", [1, 55]],
    #        [:string_embexpr, [[:var_ref, [:@ident, "there", [1, 63]]]]]]]],
    #     [:hash,
    #      [:assoclist_from_args,
    #       [[:assoc_new,
    #         [:@label, "a:", [1, 74]],
    #         [:symbol_literal, [:symbol, [:@ident, "b", [1, 78]]]]]]]]]]]]

    it 'discovers the source begin location for a variety of literals and their containing nodes' do
      input = 'arr = true, nil, 314, 4.155, ?x, /ac/ix, "Abc#{hi}", :"hello #{there}", { a: :b }'
      tree = Sexp.new(Ripper.sexp(input), '(stdin)', input)
      list = tree[1]

      list[0][1][1].source_begin.should == [1, 0]
      list[0][1].source_begin.should == [1, 0]
      list[0].source_begin.should == [1, 0]

      arglist = list[0][2]
      arglist.source_begin.should == [1, 6]
      args = arglist[1]
      # true
      args[0].source_begin.should == [1, 6]
      args[0][1].source_begin.should == [1, 6]
      # nil
      args[1].source_begin.should == [1, 12]
      args[1][1].source_begin.should == [1, 12]
      # 314
      args[2].source_begin.should == [1, 17]
      # 4.155
      args[3].source_begin.should == [1, 22]
      # ?x
      args[4].source_begin.should == [1, 29]
      # /ac/ix
      args[5].source_begin.should == [1, 33]
      args[5][1].source_begin.should == [1, 34]
      args[5][1][0].source_begin.should == [1, 34]
      args[5][2].source_begin.should == [1, 36]
      # "Abc#{hi}"
      args[6].source_begin.should == [1, 41]
      args[6][1].source_begin.should == [1, 42]
      args[6][1][1].source_begin.should == [1, 42]
      args[6][1][2].source_begin.should == [1, 45]
      args[6][1][2][1].source_begin.should == [1, 47]
      args[6][1][2][1][0].source_begin.should == [1, 47]
      args[6][1][2][1][0][1].source_begin.should == [1, 47]
      # :"hello #{there}"
      args[7].source_begin.should == [1, 53]
      args[7][1].source_begin.should == [1, 55]
      args[7][1][0].source_begin.should == [1, 55]
      args[7][1][1].source_begin.should == [1, 61]
      args[7][1][1][1].source_begin.should == [1, 63]
      args[7][1][1][1][0].source_begin.should == [1, 63]
      args[7][1][1][1][0][1].source_begin.should == [1, 63]

      # { a: :b }
      hash = arglist[2]
      hash.source_begin.should == [1, 72]
      hash[1].source_begin.should == [1, 74]
      hash[1][1].source_begin.should == [1, 74]
      hash[1][1][0].source_begin.should == [1, 74]
      hash[1][1][0][1].source_begin.should == [1, 74]
      hash[1][1][0][2].source_begin.should == [1, 77]
      hash[1][1][0][2][1].source_begin.should == [1, 78]
      hash[1][1][0][2][1][1].source_begin.should == [1, 78]
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "arr", [1, 0]]],
    #    [:mrhs_new_from_args,
    #     [[:var_ref, [:@kw, "true", [1, 6]]],
    #      [:var_ref, [:@kw, "nil", [1, 12]]],
    #      [:@int, "314", [1, 17]],
    #      [:@float, "4.155", [1, 22]],
    #      [:@CHAR, "?x", [1, 29]],
    #      [:regexp_literal,
    #       [[:@tstring_content, "ac", [1, 34]]],
    #       [:@regexp_end, "/ix", [1, 36]]],
    #      [:string_literal,
    #       [:string_content,
    #        [:@tstring_content, "Abc", [1, 42]],
    #        [:string_embexpr, [[:var_ref, [:@ident, "hi", [1, 47]]]]]]],
    #      [:dyna_symbol,
    #       [[:@tstring_content, "hello ", [1, 55]],
    #        [:string_embexpr, [[:var_ref, [:@ident, "there", [1, 63]]]]]]]],
    #     [:hash,
    #      [:assoclist_from_args,
    #       [[:assoc_new,
    #         [:@label, "a:", [1, 74]],
    #         [:symbol_literal, [:symbol, [:@ident, "b", [1, 78]]]]]]]]]]]]

    it 'discovers the source end location for a variety of literals and their containing nodes' do
      input = 'arr = true, nil, 314, 4.155, ?x, /ac/ix, "Abc#{hi}", :"hello #{there}", { a: :b }'
      tree = Sexp.new(Ripper.sexp(input), '(stdin)', input)
      list = tree[1]

      list[0][1][1].source_end.should == [1, 3]
      list[0][1].source_end.should == [1, 3]
      list[0].source_end.should == [1, 81]  # requires that we get the hash right, which we don't. TODO(adgar)

      arglist = list[0][2]
      arglist.source_end.should == [1, 81]  # for all rhs, requires forward-tracking
      args = arglist[1]
      args[0].source_end.should == [1, 10]
      args[0][1].source_end.should == [1, 10]
      args[1].source_end.should == [1, 15]
      args[1][1].source_end.should == [1, 15]
      args[2].source_end.should == [1, 20]
      args[3].source_end.should == [1, 27]
      args[4].source_end.should == [1, 31]
      args[5].source_end.should == [1, 39]
      args[5][1].source_end.should == [1, 36]
      args[5][1][0].source_end.should == [1, 36]
      args[5][2].source_end.should == [1, 39]
      args[6].source_end.should == [1, 51]
      args[6][1].source_end.should == [1, 50]
      args[6][1][1].source_end.should == [1, 45]
      args[6][1][2].source_end.should == [1, 50]
      args[6][1][2][1].source_end.should == [1, 49]
      args[6][1][2][1][0].source_end.should == [1, 49]
      args[6][1][2][1][0][1].source_end.should == [1, 49]
      args[7].source_end.should == [1, 70]
      args[7][1].source_end.should == [1, 69]
      args[7][1][0].source_end.should == [1, 61]
      args[7][1][1].source_end.should == [1, 69]
      args[7][1][1][1].source_end.should == [1, 68]
      args[7][1][1][1][0].source_end.should == [1, 68]
      args[7][1][1][1][0][1].source_end.should == [1, 68]
      # 
      hash = arglist[2]
      hash.source_end.should == [1, 81]
      hash[1].source_end.should == [1, 79]
      hash[1][1].source_end.should == [1, 79]
      hash[1][1][0].source_end.should == [1, 79]
      hash[1][1][0][1].source_end.should == [1, 76]
      hash[1][1][0][2].source_end.should == [1, 79]
      hash[1][1][0][2][1].source_end.should == [1, 79]
      hash[1][1][0][2][1][1].source_end.should == [1, 79]
    end

    # [:program,
    #  [[:assign,
    #    [:var_field, [:@ident, "arr", [1, 0]]],
    #    [:array, [[:@int, "1", [1, 8]], [:@int, "2", [2, 0]]]]]]]

    it 'discovers the locations of array literals' do
      input = "arr = [ 1, \n2 ]"
      tree = Sexp.new(Ripper.sexp(input), '(stdin)', input)
      assign = tree[1][0]
      assign.source_begin.should == [1, 0]
      assign[1].source_begin.should == [1, 0]
      assign[1].source_end.should == [1, 3]
      assign[2].source_begin.should == [1, 6]
      assign[2].source_end.should == [2, 3]
    end

    # [:program,
    #  [[:def,
    #    [:@ident, "abc", [2, 0]],
    #    [:params, nil, nil, nil, nil, nil],
    #    [:bodystmt,
    #     [[:assign, [:var_field, [:@ident, "x", [3, 2]]], [:@int, "10", [3, 6]]]],
    #     nil, nil, nil]]]]
    it 'discovers the locations of method definitons' do
      input = " def \nabc\n  x = 10\n end"
      tree = Sexp.new(Ripper.sexp(input), '(stdin)', input)
      definition = tree[1][0]
      definition.source_begin.should == [1, 1]
    end

    it 'discovers the locations of operator definitons' do
      input = " def <=>(other)\n  x = 10\n end"
      tree = Sexp.new(Ripper.sexp(input), '(stdin)', input)
      definition = tree[1][0]
      definition.source_begin.should == [1, 1]
    end

    it 'discovers the locations of singleton method definitons' do
      input = " def \n self.abc\n  x = 10\n end"
      tree = Sexp.new(Ripper.sexp(input), '(stdin)', input)
      definition = tree[1][0]
      definition.source_begin.should == [1, 1]
    end

    # [:program,
    #  [[:class,
    #    [:const_ref, [:@const, "A", [2, 0]]],
    #    [:var_ref, [:@const, "B", [2, 4]]],
    #    [:bodystmt,
    #     [[:module,
    #       [:const_ref, [:@const, "D", [4, 0]]],
    #       [:bodystmt, [[:void_stmt]], nil, nil, nil]]],
    #     nil, nil, nil]]]]
    it 'discovers the locations of class and module definitons' do
      input = "   class\nA < B; module\n\nD;end\n   end"
      tree = Sexp.new(Ripper.sexp(input), '(stdin)', input)
      klass = tree[1][0]
      klass.source_begin.should == [1, 3]
      klass[3][1][0].source_begin.should == [2, 7]
    end

    it 'discovers the locations of singleton class definitons' do
      input = "   class\nA < B;   class <<\nB;end\n   end"
      tree = Sexp.new(Ripper.sexp(input), '(stdin)', input)
      klass = tree[1][0]
      klass.source_begin.should == [1, 3]
      klass[3][1][0].source_begin.should == [2, 9]
    end
  end
  
  describe '#method_estimate' do
    
    it 'adds the #method_estimate method to Sexp' do
      Sexp.instance_methods.should include(:method_estimate)
    end

    describe 'using explicit super' do
      it 'should give an error if used outside of a method' do
        tree = annotate_all('class A991; super(); end')
        tree.deep_find { |node| node.type == :super }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should be 1
        tree.all_errors[0].should be_a(NotInMethodError)
      end

      it "should bind to the first superclass implementation of the method" do
        input = "class A992; def silly992(x); end; end; class B992 < A992; end\n" +
                'class C992 < B992; def silly992(x); super(x); end; end'
        tree = annotate_all(input)
        sexp = tree.deep_find { |node| node.type == :super }
        expected_method = ClassRegistry['A992'].instance_methods['silly992']
        sexp.method_estimate.should == Set.new([expected_method])
      end

      it 'gives an error if no superclass implements the given method' do
        input = "class A994; end; class B994 < A994; end\n" +
                'class C994 < B994; def silly994(x); super(x); end; end'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :super }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should be 1
        tree.all_errors[0].should be_a(NoSuchMethodError)
      end

      it 'gives an error if the superclass implementation has incompatible arity' do
        input = "class A987; def silly987(x, y); end; end; class B987 < A987; end\n" +
                'class C987 < B987; def silly987(x); super x; end; end'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :super }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should be 1
        tree.all_errors[0].should be_a(IncompatibleArityError)
      end

      it 'does not give an error if the superclass implementation has compatible ' +
         'arity (more complicated example)' do
        input = "class A988; def silly988(x, y=x); end; end; class B988 < A988; end\n" +
                'class C988 < B988; def silly988(x); super x; end; end'
        tree = annotate_all(input)
        tree.all_errors.should be_empty
      end

      it 'gives an error if the superclass implementation has incompatible ' +
         'arity (more complicated example)' do
        input = "class A989; def silly989(x, z, y=x, *rest); end; end; class B989 < A989; end\n" +
                'class C989 < B989; def silly989(x); super(x); end; end'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :super }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should be 1
        tree.all_errors[0].should be_a(IncompatibleArityError)
      end

      it 'does not give an error if the superclass implementation has compatible ' +
         'arity (even more complicated example)' do
        input = "class A982; def silly982(a, *rest); end; end; class B982 < A982; end\n" +
                'class C982 < B982; def silly982(x, y, z); super(x, y, z); end; end'
        tree = annotate_all(input)
        tree.all_errors.should be_empty
      end
    end

    describe 'using implicit super' do
      it 'should give an error if used outside of a method' do
        tree = annotate_all('class A994; super; end')
        tree.deep_find { |node| node.type == :zsuper }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors[0].should be_a(NotInMethodError)
      end

      it "should bind to the first superclass implementation of the method" do
        input = "class A993; def silly(x); end; end; class B993 < A993; end\n" +
                'class C993 < B993; def silly(x); super; end; end'
        tree = annotate_all(input)
        sexp = tree.deep_find { |node| node.type == :zsuper }
        expected_method = ClassRegistry['A993'].instance_methods['silly']
        sexp.method_estimate.should == Set.new([expected_method])
      end

      it 'gives an error if no superclass implements the given method' do
        input = "class A995; end; class B995 < A995; end\n" +
                'class C995 < B995; def silly995(x); super; end; end'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :zsuper }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should be 1
        tree.all_errors[0].should be_a(NoSuchMethodError)
      end

      it 'gives an error if the superclass implementation has incompatible arity' do
        input = "class A997; def silly997(x, y); end; end; class B997 < A997; end\n" +
                'class C997 < B997; def silly997(x); super; end; end'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :zsuper }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should be 1
        tree.all_errors[0].should be_a(IncompatibleArityError)
      end

      it 'does not give an error if the superclass implementation has compatible ' +
         'arity (more complicated example)' do
        input = "class A998; def silly998(x, y=x); end; end; class B998 < A998; end\n" +
                'class C998 < B998; def silly998(x); super; end; end'
        tree = annotate_all(input)
        tree.all_errors.should be_empty
      end

      it 'gives an error if the superclass implementation has incompatible ' +
         'arity (more complicated example)' do
        input = "class A999; def silly999(x, z, y=x, *rest); end; end; class B999 < A999; end\n" +
                'class C999 < B999; def silly999(x); super; end; end'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :zsuper }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should be 1
        tree.all_errors[0].should be_a(IncompatibleArityError)
      end

      it 'does not give an error if the superclass implementation has compatible ' +
         'arity (even more complicated example)' do
        input = "class A978; def silly978(a, *rest); end; end; class B978 < A978; end\n" +
                'class C978 < B978; def silly978(x, y, z); super; end; end'
        tree = annotate_all(input)
        tree.all_errors.should be_empty
      end
    end

    describe 'performing a simple no-arg implicit self call' do
      it 'should resolve to the only method when there are no subclasses' do
        input = 'class A700; def printall(x); foobar; end; def foobar(); end; end'      

        tree = annotate_all(input)
        tree.all_errors.should be_empty

        foobar_call = tree.deep_find { |node| node.type == :var_ref && node.expanded_identifier == 'foobar' }
        foobar_call.should_not be_nil
        foobar_call.method_estimate.should == [ClassRegistry['A700'].instance_methods['foobar']]
      end

      it 'should raise an error when there is no method to resolve to' do
        input = 'class A701; def printall(x); foobar; end; def foobaz(); end; end'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :var_ref && node.expanded_identifier == 'foobar' }.
             method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should == 1
        tree.all_errors.first.should be_a(NoSuchMethodError)
      end

      it 'should resolve to all possible subclass implementations' do
        input = 'class A702; def printall(x); foobar; end; def foobar(); end; end;' +
                'class A703 < A702; def foobar; end; end; class A704 < A702; def foobar; end; end;' +
                'class A705 < A703; def foobar; end; end'
        tree = annotate_all(input)
        tree.all_errors.should be_empty

        foobar_call = tree.deep_find { |node| node.type == :var_ref && node.binding.nil? &&
                                              node.expanded_identifier == 'foobar' }
        foobar_call.should_not be_nil
        foobar_call.method_estimate.should ==
            [ClassRegistry['A702'].instance_methods['foobar'],
             ClassRegistry['A703'].instance_methods['foobar'],
             ClassRegistry['A705'].instance_methods['foobar'],
             ClassRegistry['A704'].instance_methods['foobar']]
      end

      it 'should throw an error if an implementation is found, but has mismatched arity' do
        input = 'class A706; def printall(x); foobar; end; def foobar(x, y=x); end; end'
        tree = annotate_all(input)
        foobar_call = tree.deep_find { |node| node.type == :var_ref && node.binding.nil? &&
                                              node.expanded_identifier == 'foobar' }
        foobar_call.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should == 1
        tree.all_errors.first.should be_a(NoSuchMethodError)
      end
    end

    describe 'performing a method calls with a receiver (:call)' do
      it 'should resolve to the appropriate method(s) based on the receiver type' do
        input = '[1, 2].uniq!'
        tree = annotate_all(input)
        tree.all_errors.should be_empty

        uniq_call = tree.deep_find { |node| node.type == :call }
        uniq_call.should_not be_nil
        uniq_call.method_estimate.should ==
            [ClassRegistry['Array'].instance_methods['uniq!']]
      end

      it 'should resolve to the appropriate method(s) based on the receiver type' do
        input = '"hello world".center(100, "=")'
        tree = annotate_all(input)
        tree.all_errors.should be_empty

        center_call = tree.deep_find { |node| node.type == :call }
        center_call.should_not be_nil
        center_call.method_estimate.should ==
            [ClassRegistry['String'].instance_methods['center']]
        center_add_args = tree.deep_find { |node| node.type == :method_add_arg }
        center_add_args.should_not be_nil
        center_add_args.method_estimate.should ==
            [ClassRegistry['String'].instance_methods['center']]
      end

      it 'should raise an error if the method cannot be found on the given type' do
        input = '[1, 2].center(2,3)'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :call }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should == 1
        tree.all_errors.first.should be_a(NoSuchMethodError)
      end

      it 'should raise an error if the method cannot be found on any type' do
        input = 'x.hiybbprqag(2,3)'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :call }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should == 1
        tree.all_errors.first.should be_a(NoSuchMethodError)
      end

      it 'should raise an error if the method is found, but with incompatible arity' do
        input = '"hello".center(100, "=", true)'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :method_add_arg }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should == 1
        tree.all_errors.first.should be_a(NoSuchMethodError)
      end
    end

    describe 'performing method calls with an implicit receiver and parenthesized args (:fcall)' do
      it 'should resolve to all subclass methods if they all match arity' do
        input = 'class A711; def printall(x); foobar(); end; def foobar(); end; end;' +
                'class A712 < A711; def foobar; end; end; class A713 < A711; def foobar; end; end;' +
                'class A714 < A712; def foobar; end; end'
        tree = annotate_all(input)
        tree.all_errors.should be_empty

        foobar_call = tree.deep_find { |node| node.type == :fcall && node[1].expanded_identifier == 'foobar' }
        foobar_call.should_not be_nil
        foobar_call.method_estimate.should ==
            [ClassRegistry['A711'].instance_methods['foobar'],
             ClassRegistry['A712'].instance_methods['foobar'],
             ClassRegistry['A714'].instance_methods['foobar'],
             ClassRegistry['A713'].instance_methods['foobar']]
      end

      it 'should resolve to all subclass methods with matching arity' do
        input = 'class A715; def printall(x); foobar(1); end; def foobar(x, y=x); end; end;' +
                'class A716 < A715; def foobar(x, y=x); end; end; class A717 < A715; def foobar(x, y=x); end; end;' +
                'class A718 < A716; def foobar(x, y); end; end'
        tree = annotate_all(input)
        tree.all_errors.should be_empty

        foobar_call = tree.deep_find { |node| node.type == :method_add_arg && node[1][1].expanded_identifier == 'foobar' }
        foobar_call.should_not be_nil
        foobar_call.method_estimate.should ==
            [ClassRegistry['A715'].instance_methods['foobar'],
             ClassRegistry['A716'].instance_methods['foobar'],
             ClassRegistry['A717'].instance_methods['foobar']]
      end

      it 'should resolve to a single method with matched arity' do
        input = 'class A719; def printall(x); foobaz(1, 2); end; def foobaz(x, y, *rest); end; end'
        tree = annotate_all(input)
        tree.all_errors.should be_empty

        foobaz_call = tree.deep_find { |node| node.type == :method_add_arg }
        foobaz_call.should_not be_nil
        foobaz_call.method_estimate.should ==
            [ClassRegistry['A719'].instance_methods['foobaz']]
      end

      it 'should raise an error if no such method exists on any subclasses' do
        input = 'class A720; def printall(x); hiybbprqag(1, 2); end; end'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :method_add_arg }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should == 1
        tree.all_errors.first.should be_a(NoSuchMethodError)
        tree.all_errors.first.message.should include('hiybbprqag')
      end

      it 'should raise an error if no such method exists with the correct arity on any subclasses' do
        input = 'class A721; def printall(x); foobaz(1, 2); end; def foobaz(x); end; end;' +
                'class A722 < A721; def foobaz(x, y, z); end; end'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :method_add_arg }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should == 1
        tree.all_errors.first.should be_a(NoSuchMethodError)
        tree.all_errors.first.message.should include('foobaz')
      end
    end

    describe 'performing method calls with an implicit receiver and non-parenthesized args (:command)' do
      it 'should resolve to all subclass methods if they all match arity' do
        input = 'class A731; def printall(x); foobar :a; end; def foobar(a); end; end;' +
                'class A732 < A731; def foobar(b); end; end; class A733 < A731; def foobar(c); end; end;' +
                'class A734 < A732; def foobar(d); end; end'
        tree = annotate_all(input)
        tree.all_errors.should be_empty

        foobar_call = tree.deep_find { |node| node.type == :command && node[1].expanded_identifier == 'foobar' }
        foobar_call.should_not be_nil
        foobar_call.method_estimate.should ==
            [ClassRegistry['A731'].instance_methods['foobar'],
             ClassRegistry['A732'].instance_methods['foobar'],
             ClassRegistry['A734'].instance_methods['foobar'],
             ClassRegistry['A733'].instance_methods['foobar']]
      end

      it 'should resolve to all subclass methods with matching arity' do
        input = 'class A735; def printall(x); foobar 1; end; def foobar(x, y=x); end; end;' +
                'class A736 < A735; def foobar(x, y=x); end; end; class A737 < A735; def foobar(x, y=x); end; end;' +
                'class A738 < A736; def foobar(x, y); end; end'
        tree = annotate_all(input)
        tree.all_errors.should be_empty

        foobar_call = tree.deep_find { |node| node.type == :command && node[1].expanded_identifier == 'foobar' }
        foobar_call.should_not be_nil
        foobar_call.method_estimate.should ==
            [ClassRegistry['A735'].instance_methods['foobar'],
             ClassRegistry['A736'].instance_methods['foobar'],
             ClassRegistry['A737'].instance_methods['foobar']]
      end

      it 'should resolve to a single method with matched arity' do
        input = 'class A739; def printall(x); foobaz 1, 2; end; def foobaz(x, y, *rest); end; end'
        tree = annotate_all(input)
        tree.all_errors.should be_empty

        foobaz_call = tree.deep_find { |node| node.type == :command && node[1].expanded_identifier == 'foobaz' }
        foobaz_call.should_not be_nil
        foobaz_call.method_estimate.should ==
            [ClassRegistry['A739'].instance_methods['foobaz']]
      end

      it 'should raise an error if no such method exists on any subclasses' do
        input = 'class A740; def printall(x); hiybbprqag 1, 2; end; end'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :command }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should == 1
        tree.all_errors.first.should be_a(NoSuchMethodError)
        tree.all_errors.first.message.should include('hiybbprqag')
      end

      it 'should raise an error if no such method exists with the correct arity on any subclasses' do
        input = 'class A741; def printall(x); foobaz 1, 2; end; def foobaz(x); end; end;' +
                'class A742 < A741; def foobaz(x, y, z); end; end'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :command }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should == 1
        tree.all_errors.first.should be_a(NoSuchMethodError)
        tree.all_errors.first.message.should include('foobaz')
      end
    end

    describe 'handling binary operators' do
      it 'should resolve to a precise lookup when possible' do
        input = '"hello %s" % ["world!"]'
        tree = annotate_all(input)
        tree.all_errors.should be_empty

        mod_call = tree.deep_find { |node| node.type == :binary }
        mod_call.should_not be_nil
        mod_call.method_estimate.should ==
            [ClassRegistry['String'].instance_methods['%']]
      end

      it 'should resolve to all subclass operators by looking up the method with the name of the operator' do
        input = '1 + 3'
        tree = annotate_all(input)
        tree.all_errors.should be_empty

        plus_call = tree.deep_find { |node| node.type == :binary }
        plus_call.should_not be_nil
        plus_call.method_estimate.should ==
            [ClassRegistry['Fixnum'].instance_methods['+'],
             ClassRegistry['Bignum'].instance_methods['+']]
      end

      it 'should throw an error if the operator does not exist on the given type' do
        input = '"hello" - "el"'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :binary }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should == 1
        tree.all_errors.first.should be_a(NoSuchMethodError)
      end

      it 'works for custom classes' do
        input = "class A709; def +(other); end; def temp; self + 5; end; end"
        tree = annotate_all(input)

        tree.all_errors.should be_empty
        plus_call = tree.deep_find { |node| node.type == :binary }
        plus_call.should_not be_nil
        plus_call.method_estimate.should ==
            [ClassRegistry['A709'].instance_methods['+']]
      end

      it 'raises an error if, for some silly reason, the binary operator is defined but without args' do
        input = "class A710; def +(); end; def temp; self + 5; end; end"
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :binary }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should == 1
        tree.all_errors.first.should be_a(NoSuchMethodError)
        tree.all_errors.first.ast_node.type.should == :binary
      end
    end

    describe 'handling unary operators' do
      it 'should resolve to all subclass operators by looking up the method with the name of the operator' do
        input = '-3'
        tree = annotate_all(input)
        tree.all_errors.should be_empty

        minus_call = tree.deep_find { |node| node.type == :unary }
        minus_call.should_not be_nil
        minus_call.method_estimate.should ==
            [ClassRegistry['Numeric'].instance_methods['-@'],
             ClassRegistry['Fixnum'].instance_methods['-@'],
             ClassRegistry['Bignum'].instance_methods['-@']]
      end

      it 'raises an error when the the operator does not exist on the given type' do
        input = '-"hello"'
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :unary }.method_estimate.should == []
        tree.all_errors.should_not be_empty
        tree.all_errors.size.should == 1
        tree.all_errors.first.should be_a(NoSuchMethodError)
      end

      it 'works for custom classes' do
        input = "class A708; def +@; end; def temp; +self; end; end"
        tree = annotate_all(input)

        tree.all_errors.should be_empty
        plus_call = tree.deep_find { |node| node.type == :unary }
        plus_call.should_not be_nil
        plus_call.method_estimate.should ==
            [ClassRegistry['A708'].instance_methods['+@']]
      end

      it 'raises an error if, for some silly reason, the unary operator is defined but with args' do
        input = "class A707; def +@(arg1, arg2); end; def temp; +self; end; end"
        tree = annotate_all(input)
        tree.deep_find { |node| node.type == :unary }.method_estimate.should == []

        tree.all_errors.should_not be_empty
        tree.all_errors.size.should == 1
        tree.all_errors.first.should be_a(NoSuchMethodError)
        tree.all_errors.first.ast_node.type.should == :unary
      end
    end
  end
end