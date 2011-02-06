require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe CommentAttachmentAnnotation do
  extend AnalysisHelpers
  clean_registry
  
  it_should_behave_like 'an annotator'
  
  it 'adds the #docstring method to Sexp' do
    Sexp.instance_methods.should include(:comment)
  end
  
  # [:program,
  # [[:def,
  #   [:@ident, "silly", [3, 4]],
  #   [:paren,
  #    [:params,
  #     [[:@ident, "a", [3, 10]], [:@ident, "b", [3, 13]]],
  #     nil,
  #     nil,
  #     nil,
  #     nil]],
  #   [:bodystmt, [[:void_stmt]], nil, nil, nil]],
  #  [:class,
  #   [:const_ref, [:@const, "A", [6, 7]]],
  #   nil,
  #   [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]
  it 'discovers the comments before a method and class declaration' do
    input = "  # abc\n  #  def\ndef silly(a, b)\n end\n # a class\n class A990; end"
    tree = annotate_all(input)
    list = tree[1]
    
    defn = list[0]
    defn.comment.body.should == " abc\n  def"
    klass_defn = list[1]
    klass_defn.comment.body.should == " a class"
  end
  
  # [:program,
  #  [[:def,
  #    [:@ident, "some_method", [3, 6]],
  #    [:paren, [:params, [[:@ident, "abc", [3, 18]]], nil, nil, nil, nil]],
  #    [:bodystmt,
  #     [[:assign,
  #       [:var_field, [:@ident, "y", [5, 4]]],
  #       [:binary,
  #        [:var_ref, [:@ident, "abc", [5, 8]]],
  #        :*,
  #        [:@int, "2", [5, 14]]]]],
  #     nil, nil, nil]]]]
  
  it 'discovers comments before introduction of a new local variable' do
    input = <<-EOF
  # some method
  # abc: String
  def some_method(abc)
    # y: String
    y = abc * 2
  end
EOF
    tree = annotate_all(input)

    list = tree[1]
    defn = list[0]
    defn.comment.body.should == " some method\n abc: String"
    assignment = defn[3][1][0]
    assignment.comment.body.should == " y: String"
  end
end