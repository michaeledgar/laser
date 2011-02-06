require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe SourceLocationAnnotation do
  extend AnalysisHelpers
  clean_registry
  
  it_should_behave_like 'an annotator'
  
  it 'adds the #source_begin method to Sexp' do
    Sexp.instance_methods.should include(:source_begin)
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
  
  it 'discovers the source begin location for a variety of literals and their containing nodes' do
    input = 'arr = true, nil, 314, 4.155, ?x, /ac/ix, "Abc#{hi}", :"hello #{there}", { a: :b }'
    tree = Sexp.new(Ripper.sexp(input))
    SourceLocationAnnotation.new.annotate_with_text(tree, input)
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
    tree = Sexp.new(Ripper.sexp(input))
    SourceLocationAnnotation.new.annotate_with_text(tree, input)
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
    tree = Sexp.new(Ripper.sexp(input))
    SourceLocationAnnotation.new.annotate_with_text(tree, input)
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
    tree = Sexp.new(Ripper.sexp(input))
    SourceLocationAnnotation.new.annotate_with_text(tree, input)
    definition = tree[1][0]
    definition.source_begin.should == [1, 1]
  end
  
  it 'discovers the locations of operator definitons' do
    input = " def <=>(other)\n  x = 10\n end"
    tree = Sexp.new(Ripper.sexp(input))
    SourceLocationAnnotation.new.annotate_with_text(tree, input)
    definition = tree[1][0]
    definition.source_begin.should == [1, 1]
  end
  
  it 'discovers the locations of singleton method definitons' do
    input = " def \n self.abc\n  x = 10\n end"
    tree = Sexp.new(Ripper.sexp(input))
    SourceLocationAnnotation.new.annotate_with_text(tree, input)
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
    tree = Sexp.new(Ripper.sexp(input))
    SourceLocationAnnotation.new.annotate_with_text(tree, input)
    klass = tree[1][0]
    klass.source_begin.should == [1, 3]
    klass[3][1][0].source_begin.should == [2, 7]
  end
  
  it 'discovers the locations of singleton class definitons' do
    input = "   class\nA < B;   class <<\nB;end\n   end"
    tree = Sexp.new(Ripper.sexp(input))
    SourceLocationAnnotation.new.annotate_with_text(tree, input)
    klass = tree[1][0]
    klass.source_begin.should == [1, 3]
    klass[3][1][0].source_begin.should == [2, 9]
  end
end