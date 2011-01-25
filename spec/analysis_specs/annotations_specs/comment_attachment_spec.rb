require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe CommentAttachmentAnnotation do
  extend AnalysisHelpers
  clean_registry
  
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
  
  
  it 'discovers the comments before a method declaration' do
    input = "  # abc\n  #  def\ndef silly(a, b)\n end\n # a class\n class A; end"
    tree = Sexp.new(Ripper.sexp(input))
    # source location is *required* for CommentAttachment to work.
    SourceLocationAnnotation::Annotator.new.annotate_with_text(tree, input)
    CommentAttachmentAnnotation::Annotator.new.annotate_with_text(tree, input)
    list = tree[1]
    
    defn = list[0]
    defn.comment.body.should == " abc\n  def\n"
    klass_defn = list[1]
    klass_defn.comment.body.should == " a class\n"
  end
end