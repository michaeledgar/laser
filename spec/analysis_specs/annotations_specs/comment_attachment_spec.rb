require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe CommentAttachmentAnnotation do
  extend AnalysisHelpers
  clean_registry
  
  it 'adds the #docstring method to Sexp' do
    Sexp.instance_methods.should include(:docstring)
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
  
  it 'discovers the comments before a method declaration', :focus => true do
    input = "  # abc\n  # def\ndef silly(a, b)\n end"
    tree = Sexp.new(Ripper.sexp(input))
    CommentAttachmentAnnotation::Annotator.new.annotate_with_text(tree, input)
    list = tree[1]
  end
end