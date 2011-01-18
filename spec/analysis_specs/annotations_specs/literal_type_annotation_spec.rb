require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe ScopeAnnotation do
  extend AnalysisHelpers
  clean_registry
  
  it 'adds the #class_estimate method to Sexp' do
    Sexp.instance_methods.should include(:class_estimate)
  end
  
  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # [:program,
  # [[:assign,
  #    [:var_field, [:@ident, "a", [1, 0]]], [:@int, "5", [1, 4]]]]]
  it 'discovers the class for integer literals' do
    tree = Sexp.new(Ripper.sexp('a = 5'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['Fixnum']
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
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    [list[0][2], list[0][2][1], list[0][2][1][1], list[0][2][1][2]].each do |entry|
      estimate = entry.class_estimate
      estimate.should be_exact
      estimate.exact_class.should == ClassRegistry['String']
    end
  end

  # [:program,
  # [[:assign,
  #   [:var_field, [:@ident, "a", [1, 0]]],
  #   [:xstring_literal, [[:@tstring_content, "find .", [1, 7]]]]]]]
  it 'discovers the class for executed string literals' do
    tree = Sexp.new(Ripper.sexp('a = %x(find .)'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['String']
  end

  # [:program,
  #  [[:assign,
  #     [:var_field, [:@ident, "a", [1, 0]]],
  #     [:@CHAR, "?a", [1, 4]]]]]
  it 'discovers the class for character literals' do
    tree = Sexp.new(Ripper.sexp('a = ?a'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['String']
  end
  
  # [:program,
  # [[:assign,
  #    [:var_field, [:@ident, "x", [1, 0]]],
  #    [:@float, "3.14", [1, 4]]]]]
  it 'discovers the class for float literals' do
    tree = Sexp.new(Ripper.sexp('x = 3.14'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['Float']
  end
  
  # [:program,
  # [[:assign,
  #   [:var_field, [:@ident, "x", [1, 0]]],
  #   [:regexp_literal,
  #    [[:@tstring_content, "abc", [1, 5]]],
  #    [:@regexp_end, "/im", [1, 8]]]]]]
  it 'discovers the class for regexp literals' do
    tree = Sexp.new(Ripper.sexp('x = /abc/im'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['Regexp']
  end
  
  # [:program,
  #  [[:assign,
  #    [:var_field, [:@ident, "x", [1, 0]]],
  #    [:array, [[:@int, "1", [1, 5]], [:@int, "2", [1, 8]]]]]]]
  it 'discovers the class for array literals' do
    tree = Sexp.new(Ripper.sexp('x = [1, 2]'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['Array']
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
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['Hash']
  end
  
  # [:program,
  #  [[:assign,
  #    [:var_field, [:@ident, "x", [1, 0]]],
  #    [:symbol_literal, [:symbol, [:@ident, "abcdef", [1, 5]]]]]]]
  it 'discovers the class for symbol literals' do
    tree = Sexp.new(Ripper.sexp('x = :abcdef'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['Symbol']
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
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['Symbol']
  end

  # [:program,
  #  [[:assign,
  #    [:var_field, [:@ident, "x", [1, 0]]],
  #    [:var_ref, [:@kw, "true", [1, 4]]]]]]
  it 'discovers the class for true' do
    tree = Sexp.new(Ripper.sexp('x = true'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['TrueClass']
  end

  # [:program,
  #  [[:assign,
  #    [:var_field, [:@ident, "x", [1, 0]]],
  #    [:var_ref, [:@kw, "false", [1, 4]]]]]]
  it 'discovers the class for false' do
    tree = Sexp.new(Ripper.sexp('x = false'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['FalseClass']
  end

  # [:program,
  #  [[:assign,
  #    [:var_field, [:@ident, "x", [1, 0]]],
  #    [:var_ref, [:@kw, "nil", [1, 4]]]]]]
  it 'discovers the class for nil' do
    tree = Sexp.new(Ripper.sexp('x = nil'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['NilClass']
  end

  # [:program,
  #  [[:assign,
  #    [:var_field, [:@ident, "x", [1, 0]]],
  #    [:var_ref, [:@kw, "__FILE__", [1, 4]]]]]]
  it 'discovers the class for __FILE__' do
    tree = Sexp.new(Ripper.sexp('x = __FILE__'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['String']
  end

  # [:program,
  #  [[:assign,
  #    [:var_field, [:@ident, "x", [1, 0]]],
  #    [:var_ref, [:@kw, "__LINE__", [1, 4]]]]]]
  it 'discovers the class for __LINE__' do
    tree = Sexp.new(Ripper.sexp('x = __LINE__'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['Fixnum']
  end
  

  # [:program,
  #  [[:assign,
  #    [:var_field, [:@ident, "x", [1, 0]]],
  #    [:var_ref, [:@kw, "__LINE__", [1, 4]]]]]]
  it 'discovers the class for __ENCODING__' do
    tree = Sexp.new(Ripper.sexp('x = __ENCODING__'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['Encoding']
  end
  
  
  # [:program,
  # [[:assign,
  #   [:var_field, [:@ident, "x", [1, 0]]],
  #   [:dot2, [:@int, "2", [1, 4]], [:@int, "9", [1, 7]]]]]]
  it 'discovers the class for inclusive ranges' do
    tree = Sexp.new(Ripper.sexp('x = 2..9'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['Range']
  end
  
  
  # [:program,
  # [[:assign,
  #   [:var_field, [:@ident, "x", [1, 0]]],
  #   [:dot3, [:@int, "2", [1, 4]], [:@int, "9", [1, 8]]]]]]
  it 'discovers the class for exclusive ranges' do
    tree = Sexp.new(Ripper.sexp('x = 2...9'))
    LiteralTypeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    estimate = list[0][2].class_estimate
    estimate.should be_exact
    estimate.exact_class.should == ClassRegistry['Range']
  end
end