require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'
describe RuntimeAnnotation do
  it_should_behave_like 'an annotator'
  
  it 'adds the #runtime method to Sexp' do
    Sexp.instance_methods.should include(:runtime)
  end

  # [:program,
  #  [[:assign,
  #    [:var_field, [:@ident, "abc", [1, 0]]],
  #    [:var_ref, [:@const, "ABC", [1, 6]]]]]]
  it 'handles nested module/class declarations' do
    input = 'module A; module B; class C; end; class D < C; end; end; end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate_with_text(tree, input)
    tree.all_subtrees.each { |subtree| subtree.runtime.should == :load }
  end
  
  # [:program,
  #  [[:module,
  #    [:const_ref, [:@const, "A", [1, 7]]],
  #    [:bodystmt,
  #     [[:void_stmt],
  #      [:module,
  #       [:const_ref, [:@const, "B", [1, 17]]],
  #       [:bodystmt,
  #        [[:void_stmt],
  #         [:def,
  #          [:@ident, "abc", [1, 24]],
  #          [:paren,
  #           [:params,
  #            [[:@ident, "xyz", [1, 28]]],
  #            [[[:@ident, "jkl", [1, 33]],
  #              [:binary,
  #               [:var_ref, [:@ident, "xyz", [1, 37]]],
  #               :*,
  #               [:@int, "2", [1, 41]]]]],
  #            nil, nil, nil]],
  #          [:bodystmt,
  #           [[:void_stmt],
  #            [:command,
  #             [:@ident, "p", [1, 45]],
  #             [:args_add_block, [[:var_ref, [:@ident, "xyz", [1, 47]]]], false]],
  #            [:def,
  #             [:@ident, "another", [1, 56]],
  #             [:params, nil, nil, nil, nil, nil],
  #             [:bodystmt, [[:void_stmt]], nil, nil, nil]]],
  #           nil, nil, nil]]],
  #        nil, nil, nil]]],
  #     nil, nil, nil]]]]
  it 'handles regular method definitions' do
    input = 'module A; module B; def abc(xyz, jkl=xyz*2); p xyz; def another; end; end; end; end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate_with_text(tree, input)
    mod_a = tree[1][0]
    mod_b = mod_a[2][1][1]
    defn = mod_b[2][1][1]
    expectalot(:runtime => {
                 :load => [tree, tree[1], mod_a, mod_a[1], mod_a[2], mod_a[2][1],
                          mod_a[2][1][0], mod_b, mod_b[1], mod_b[1][1], defn, defn[1]],
                 :run => [*defn[2].all_subtrees, *defn[3].all_subtrees]
               })
  end
end