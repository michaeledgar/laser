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
  
  # [:program,
  #  [[:module,
  #    [:const_ref, [:@const, "A", [1, 7]]],
  #    [:bodystmt,
  #     [[:void_stmt],
  #      [:method_add_block,
  #       [:call,
  #        [[:@tstring_content, "a,", [1, 13]], [:@tstring_content, "b", [1, 16]]],
  #        :".",
  #        [:@ident, "each", [1, 19]]],
  #       [:brace_block,
  #        [:block_var,
  #         [:params, [[:@ident, "x", [1, 26]]], nil, nil, nil, nil],
  #         nil],
  #        [[:method_add_block,
  #          [:method_add_arg,
  #           [:fcall, [:@ident, "define_method", [1, 29]]],
  #           [:arg_paren,
  #            [:args_add_block, [[:var_ref, [:@ident, "x", [1, 43]]]], false]]],
  #          [:do_block,
  #           nil,
  #           [[:void_stmt], [:var_ref, [:@ident, "x", [1, 50]]]]]]]]]],
  #     nil, nil, nil]]]]
  
  it 'gives up on blocks that are captured at load-time' do
    # not unrealistic code! Sometime we need to know this executes at load-time!
    input = 'module A; %w(a b).each {|x| define_method(x) do; x; end}; end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate_with_text(tree, input)
    mod_a = tree[1][0]
    mab_node = mod_a[2][1][1]
    expectalot(:runtime => {
                 :load => [tree, tree[1], mod_a, mod_a[1], mod_a[2], mod_a[2][1],
                           mab_node, mab_node[1]],
                 :unknown => mab_node[2].all_subtrees
               })
  end
  
  # [:program,
  #  [[:def,
  #    [:@ident, "k", [1, 4]],
  #    [:params, nil, nil, nil, nil, nil],
  #    [:bodystmt,
  #     [[:method_add_block,
  #       [:call,
  #        [[:@tstring_content, "a", [1, 10]], [:@tstring_content, "b", [1, 12]]],
  #        :".",
  #        [:@ident, "each", [1, 15]]],
  #       [:brace_block,
  #        [:block_var,
  #         [:params, [[:@ident, "x", [1, 22]]], nil, nil, nil, nil],
  #         nil],
  #        [[:method_add_block,
  #          [:method_add_arg,
  #           [:fcall, [:@ident, "define_method", [1, 25]]],
  #           [:arg_paren,
  #            [:args_add_block, [[:var_ref, [:@ident, "x", [1, 39]]]], false]]],
  #          [:do_block,
  #           nil,
  #           [[:void_stmt], [:var_ref, [:@ident, "x", [1, 46]]]]]]]]]],
  #     nil, nil, nil]]]]
  it 'knows blocks captured at run-time retain run-time status' do
    input = 'def k; %w(a b).each {|x| define_method(x) do; x; end}; end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate_with_text(tree, input)
    defn = tree[1][0]
    expectalot(:runtime => { :run => defn[3].all_subtrees })
  end
end