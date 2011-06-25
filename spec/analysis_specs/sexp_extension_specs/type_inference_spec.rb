require_relative 'spec_helper'

describe Sexp do
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
end