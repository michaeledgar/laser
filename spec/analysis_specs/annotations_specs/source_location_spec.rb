require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe SourceLocationAnnotation do
  extend AnalysisHelpers
  clean_registry
  
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
  
  it 'discovers the source location for a variety of literals and their containing nodes' do
    input = 'arr = true, nil, 314, 4.155, ?x, /ac/ix, "Abc#{hi}", :"hello #{there}", { a: :b }'
    tree = Sexp.new(Ripper.sexp(input))
    SourceLocationAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    
    list[0][1][1].source_begin.should == [1, 0]
    list[0][1].source_begin.should == [1, 0]
    list[0].source_begin.should == [1, 0]
    
    arglist = list[0][2]
    arglist.source_begin.should == [1, 6]  # for 'true'
    args = arglist[1]
    args[0].source_begin.should == [1, 6]
    args[0][1].source_begin.should == [1, 6]
    args[1].source_begin.should == [1, 12]
    args[1][1].source_begin.should == [1, 12]
    args[2].source_begin.should == [1, 17]
    args[3].source_begin.should == [1, 22]
    args[4].source_begin.should == [1, 29]
    args[5].source_begin.should == [1, 34]
    args[5][1].source_begin.should == [1, 34]
    args[5][1][0].source_begin.should == [1, 34]
    args[5][2].source_begin.should == [1, 36]
    args[6].source_begin.should == [1, 42]
    args[6][1].source_begin.should == [1, 42]
    args[6][1][1].source_begin.should == [1, 42]
    args[6][1][2].source_begin.should == [1, 47]
    args[6][1][2][1].source_begin.should == [1, 47]
    args[6][1][2][1][0].source_begin.should == [1, 47]
    args[6][1][2][1][0][1].source_begin.should == [1, 47]
    #args[7].source_begin.should == [1, 54]  # This requires backtracking to find the : char!
    args[7][1].source_begin.should == [1, 55]
    args[7][1][0].source_begin.should == [1, 55]
    args[7][1][1].source_begin.should == [1, 63]
    args[7][1][1][1].source_begin.should == [1, 63]
    args[7][1][1][1][0].source_begin.should == [1, 63]
    args[7][1][1][1][0][1].source_begin.should == [1, 63]

    hash = arglist[2]
    #hash.source_begin.should == [1, 72]  # This requires backtracking to find the { char!
    hash[1].source_begin.should == [1, 74]
    hash[1][1].source_begin.should == [1, 74]
    hash[1][1][0].source_begin.should == [1, 74]
    hash[1][1][0][1].source_begin.should == [1, 74]
    hash[1][1][0][2].source_begin.should == [1, 78]
    hash[1][1][0][2][1].source_begin.should == [1, 78]
    hash[1][1][0][2][1][1].source_begin.should == [1, 78]
    
  end
end