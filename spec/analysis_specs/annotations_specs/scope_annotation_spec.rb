require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'
describe ScopeAnnotation do
  extend AnalysisHelpers
  clean_registry
  
  it 'adds the #scope method to Sexp' do
    Sexp.instance_methods.should include(:scope)
  end
  
  it 'adds scopes to each node with a flat example with no new scopes' do
    tree = Sexp.new(Ripper.sexp('p 5; if b; a; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    tree.all_subtrees.each do |node|
      node.scope.should == Scope::GlobalScope
    end
  end
  
  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # sexp = [:program,
  #        [[:assign, [:var_field, [:@ident, "a", [1, 0]]], [:var_ref, [:@kw, "nil", [1, 4]]]],
  #         [:module, [:const_ref, [:@const, "A", [1, 16]]],
  #           [:bodystmt, [[:void_stmt], [:assign, [:var_field, [:@ident, "a", [1, 19]]],
  #           [:@int, "10", [1, 23]]]], nil, nil, nil]]]]
  it 'creates a new scope when a simple module declaration is encountered' do
    tree = Sexp.new(Ripper.sexp('p 5; module A; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    with_new_scope = list[1][2], *list[1][2].all_subtrees
    expectalot(scope: { Scope::GlobalScope => [tree, list[0], list[0][1], list[0][2]],
                           Scope::GlobalScope.lookup('A').scope => with_new_scope })

    list[1][2].scope.should be_a(ClosedScope)
    list[1][2].scope.self_ptr.klass.path.should == 'Module'
    list[1][2].scope.self_ptr.path.should == 'A'
  end
  
  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # sexp = [:program,
  #        [[:assign, [:var_field, [:@ident, "a", [1, 0]]], [:var_ref, [:@kw, "nil", [1, 4]]]],
  #         [:module, [:top_const_ref, [:@const, "B", [1, 18]]],
  #           [:bodystmt, [[:void_stmt], [:assign, [:var_field, [:@ident, "a", [1, 21]]],
  #           [:@int, "10", [1, 25]]]], nil, nil, nil]]]]
  it 'creates a new scope when a simple top-pathed module declaration is encountered' do
    tree = Sexp.new(Ripper.sexp('p 5; module ::B; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    list[1][2].scope.self_ptr.name.should == 'B'
    list[1][2].scope.should be_a(ClosedScope)

    with_new_scope = list[1][2], *list[1][2].all_subtrees
    expectalot(scope: { Scope::GlobalScope => [tree, list[0], list[0][1], list[0][2]],
                           Scope::GlobalScope.lookup('B').scope => with_new_scope })
  end
  
  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # [:program,
  # [[:module,
  #   [:const_path_ref,
  #    [:var_ref, [:@const, "ABC", [1, 7]]],
  #    [:@const, "DEF", [1, 12]]],
  #   [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]
  it 'creates a new scope when a pathed module declaration is encountered' do
    temp_scope = ClosedScope.new(Scope::GlobalScope, nil)
    temp_mod = LaserModule.new('ABC', temp_scope)
    tree = Sexp.new(Ripper.sexp('p 5; module ABC::DEF; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    mod = list[1][2].scope.self_ptr
    #mod.class_used.path.should == 'ABC::DEF'
    mod.klass.path.should == 'Module'
    mod.path.should == 'ABC::DEF'
    mod.name.should == 'DEF'
    mod.scope.parent.self_ptr.name.should == 'ABC'
    mod.scope.should be_a(ClosedScope)

    with_new_scope = list[1][2], *list[1][2].all_subtrees
    expectalot(scope: { Scope::GlobalScope => [tree, list[0], list[0][1], list[0][2]],
                           temp_scope.lookup('DEF').scope => with_new_scope })
  end
  
  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # sexp = [:program, [
  #         [:module, [:const_path_ref, [:var_ref, [:@const, "A10", [1, 7]]], [:@const, "B12", [1, 12]]],
  #           [:bodystmt, [[:void_stmt]], nil, nil, nil]],
  #         [:module, [:const_path_ref, [:var_ref, [:@const, "A10", [1, 29]]], [:@const, "B12", [1, 34]]],
  #           [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]
  it 'creates a new scope when a simple module declaration is encountered' do
    temp_scope = ClosedScope.new(Scope::GlobalScope, nil)
    temp_mod = LaserModule.new('A10', temp_scope)
    tree = Sexp.new(Ripper.sexp('module A10::B12; end; module A10::B12; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    
    list = tree[1]
    with_new_scope = [list[0][2], *list[0][2].all_subtrees] +
                     [list[1][2], *list[1][2].all_subtrees]
    expectalot(scope: { Scope::GlobalScope => [tree, list[0], list[0][1], list[1][1]],
                           temp_scope.lookup('B12').scope => with_new_scope })

    list[0][2].scope.should be_a(ClosedScope)
    list[0][2].scope.self_ptr.name.should == 'B12'
    list[1][2].scope.self_ptr.name.should == 'B12'
    
    # *MUST* Be same objects because this is how we implement re-opening - the
    # second has to modify the same scope as before!
    list[0][2].scope.object_id.should == list[1][2].scope.object_id
  end

  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # sexp = [:program, [
  #         [:module, [:const_ref, [:@const, "A", [1, 7]]],
  #           [:bodystmt, [[:void_stmt],
  #            [:module, [:const_ref, [:@const, "B", [1, 17]]],
  #              [:bodystmt, [[:void_stmt],
  #               [:module, [:const_ref, [:@const, "C", [1, 27]]],
  #                 [:bodystmt, [[:void_stmt]],
  #                  nil, nil, nil]]], nil, nil, nil]]], nil, nil, nil]]]]
  it 'creates several new scopes when a bunch of nested modules are encountered' do
    tree = Sexp.new(Ripper.sexp('module A; module B32; module C444; end; end; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    a_body = list[0][2]
    b_body = a_body[1][1][2]
    c_body = b_body[1][1][2]
    [a_body, b_body, c_body].each { |x| x.scope.should be_a(ClosedScope) }
    a, b, c = [a_body, b_body, c_body].map { |x| x.scope.self_ptr }
    
    
    a.klass.path.should == 'Module'
    b.klass.path.should == 'Module'
    c.klass.path.should == 'Module'
    a.path.should == 'A'
    b.path.should == 'A::B32'
    c.path.should == 'A::B32::C444'
    a.name.should == 'A'
    b.name.should == 'B32'
    c.name.should == 'C444'
  end
  
  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # [:program,
  #  [[:module,
  #    [:const_ref, [:@const, "M13", [1, 7]]],
  #    [:bodystmt,
  #     [[:void_stmt],
  #      [:def,
  #       [:@ident, "silly", [1, 16]],
  #       [:paren,
  #        [:params, nil, nil, [:rest_param, [:@ident, "rest", [1, 23]]], nil, nil]],
  #       [:bodystmt,
  #        [[:void_stmt],
  #         [:command,
  #          [:@ident, "p", [1, 30]],
  #          [:args_add_block, [[:var_ref, [:@ident, "rest", [1, 32]]]], false]]],
  #        nil,  nil, nil]]],
  #     nil, nil, nil]]]]
  it 'defines methods on the current Module, if inside a module lexically' do
    tree = Sexp.new(Ripper.sexp('module M13; def silly(*rest); p rest; end; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0][2][1][1]
    body = definition[3]
    [body, *body.all_subtrees].each do |node|
      new_scope = node.scope
      new_scope.self_ptr.should be_a(LaserObject)
      new_scope.self_ptr.klass.should == ClassRegistry['M13']
      new_scope.locals.should_not be_empty
      new_scope.lookup('rest').should == Bindings::ArgumentBinding.new('rest', LaserObject.new(ClassRegistry['Array']), :rest)
    end
    # now make sure the method got created in the M13 module!
    method = ClassRegistry['M13'].instance_methods['silly']
    method.should_not be_nil
    method.signatures.size.should == 1
    signature = method.signatures.first
    signature.arguments.should == [body.scope.lookup('rest')]
    signature.name.should == 'silly'
  end
  
  # [:program,
  #  [[:module,
  #    [:const_ref, [:@const, "M49", [1, 7]]],
  #    [:bodystmt,
  #     [[:void_stmt],
  #      [:defs,
  #       [:var_ref, [:@kw, "self", [1, 16]]],
  #       [:@period, ".", [1, 20]],
  #       [:@ident, "silly", [1, 21]],
  #       [:paren,
  #        [:params,
  #         [[:@ident, "a", [1, 27]]],
  #         [[[:@ident, "b", [1, 30]], [:var_ref, [:@ident, "a", [1, 32]]]]],
  #         nil, nil, nil]],
  #       [:bodystmt, [[:void_stmt]], nil, nil, nil]]],
  #     nil, nil, nil]]]]
  it "allows singleton method declarations on a Module's self" do
    tree = Sexp.new(Ripper.sexp('module M49; def self.silly(a, b=a); end; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0][2][1][1]
    body = definition[5]
    [body, *body.all_subtrees].each do |node|
      new_scope = node.scope
      new_scope.self_ptr.should be_a(LaserModule)
      new_scope.self_ptr.should == ClassRegistry['M49']
      new_scope.self_ptr.klass.should == ClassRegistry['Module']
      new_scope.locals.should_not be_empty
      new_scope.lookup('a').should == Bindings::ArgumentBinding.new('a', LaserObject.new, :positional)
      new_scope.lookup('b').should == Bindings::ArgumentBinding.new(
          'b', LaserObject.new, :optional,
          Sexp.new([:var_ref, [:@ident, "a", [1, 32]]]))
    end
    
    method = ClassRegistry['M49'].singleton_class.instance_methods['silly']
    method.should_not be_nil
    method.signatures.size.should == 1
    signature = method.signatures.first
    signature.arguments.should == [body.scope.lookup('a'), body.scope.lookup('b')]
    signature.name.should == 'silly'
  end
  
  # [:program,
  # [[:module,
  #   [:const_ref, [:@const, "M49", [1, 7]]],
  #   [:bodystmt,
  #    [[:void_stmt],
  #     [:sclass,
  #      [:var_ref, [:@kw, "self", [1, 21]]],
  #      [:bodystmt,
  #       [[:def,
  #         [:@ident, "silly", [1, 31]],
  #         [:paren,
  #          [:params,
  #           [[:@ident, "a", [1, 37]]],
  #           [[[:@ident, "b", [1, 40]], [:var_ref, [:@ident, "a", [1, 42]]]]],
  #           nil, nil, nil]],
  #         [:bodystmt, [[:void_stmt]], nil, nil, nil]]],
  #       nil, nil, nil]]],
  #    nil, nil, nil]]]]
  it "allows singleton method declarations on a Module's self using sclass opening" do
    tree = Sexp.new(Ripper.sexp('module M50; class << self; def silly(a, b=a); end; end; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    sclass_body = tree[1][0][2][1][1][2]
    definition = sclass_body[1][0]
    body = definition[3]
    [body, *body.all_subtrees].each do |node|
      new_scope = node.scope
      new_scope.self_ptr.should be_a(LaserModule)
      new_scope.self_ptr.should == ClassRegistry['M50']
      new_scope.self_ptr.klass.should == ClassRegistry['Module']
      new_scope.locals.should_not be_empty
      new_scope.lookup('a').should == Bindings::ArgumentBinding.new('a', LaserObject.new, :positional)
      new_scope.lookup('b').should == Bindings::ArgumentBinding.new(
          'b', LaserObject.new, :optional,
          Sexp.new([:var_ref, [:@ident, "a", [1, 32]]]))
    end
    
    method = ClassRegistry['M50'].singleton_class.instance_methods['silly']
    method.should_not be_nil
    method.signatures.size.should == 1
    signature = method.signatures.first
    signature.arguments.should == [body.scope.lookup('a'), body.scope.lookup('b')]
    signature.name.should == 'silly'
  end
  
  # [:program,
  # [[:class,
  #   [:const_ref, [:@const, "C51", [1, 6]]],
  #   nil,
  #   [:bodystmt, [[:void_stmt]], nil, nil, nil]],
  #  [:sclass,
  #   [:var_ref, [:@const, "C51", [1, 25]]],
  #   [:bodystmt,
  #    [[:def,
  #      [:@ident, "silly", [1, 34]],
  #      [:paren,
  #       [:params,
  #        [[:@ident, "a", [1, 40]]],
  #        [[[:@ident, "b", [1, 43]], [:var_ref, [:@ident, "a", [1, 45]]]]],
  #        nil, nil, nil]],
  #      [:bodystmt, [[:void_stmt]], nil, nil, nil]]],
  #    nil, nil, nil]]]]
  
  it "allows singleton method declarations on a Module's self using sclass opening" do
    tree = Sexp.new(Ripper.sexp('class C51; end; class << C51; def silly(a, b=a); end; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    sclass_body = tree[1][1][2]
    definition = sclass_body[1][0]
    body = definition[3]
    [body, *body.all_subtrees].each do |node|
      new_scope = node.scope
      new_scope.self_ptr.should be_a(LaserClass)
      new_scope.self_ptr.should == ClassRegistry['C51']
      new_scope.self_ptr.klass.should == ClassRegistry['Class']
      new_scope.locals.should_not be_empty
      new_scope.lookup('a').should == Bindings::ArgumentBinding.new('a', LaserObject.new, :positional)
      new_scope.lookup('b').should == Bindings::ArgumentBinding.new(
          'b', LaserObject.new, :optional,
          Sexp.new([:var_ref, [:@ident, "a", [1, 32]]]))
    end
    
    method = ClassRegistry['C51'].singleton_class.instance_methods['silly']
    method.should_not be_nil
    method.signatures.size.should == 1
    signature = method.signatures.first
    signature.arguments.should == [body.scope.lookup('a'), body.scope.lookup('b')]
    signature.name.should == 'silly'
  end
  
  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # sexp = [:program, [
  #         [:class, [:const_ref, [:@const, "A", [1, 6]]], nil,
  #           [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]
  it 'creates a new scope when a class declaration is encountered' do
    tree = Sexp.new(Ripper.sexp('class C99; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    a_header = list[0][1]
    a_body = list[0][3]
    a_body.scope.should be_a(ClosedScope)
    a = a_body.scope.self_ptr
    
    a_header.scope.should == Scope::GlobalScope
    a.klass.path.should == 'Class'
    a.path.should == 'C99'
    a.superclass.should == ClassRegistry['Object']
  end
  
  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # sexp = [:program, [
  #         [:class, [:const_ref, [:@const, "C89", [1, 6]]], nil,
  #           [:bodystmt, [[:void_stmt]], nil, nil, nil]],
  #         [:class, [:const_ref, [:@const, "CPP", [1, 22]]], [:var_ref, [:@const, "C89", [1, 28]]],
  #           [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]
  it 'creates a new class with the appropriate superclass when specified' do
    tree = Sexp.new(Ripper.sexp('class C89; end; class CPP < C89; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    a_header = list[0][1]
    a_body = list[0][3]
    b_header = list[1][1]
    b_body = list[1][3]
    [a_body, b_body].each { |x| x.scope.should be_a(ClosedScope) }
    a, b = a_body.scope.self_ptr, b_body.scope.self_ptr
    
    a_header.scope.should == Scope::GlobalScope
    a.klass.path.should == 'Class'
    a.path.should == 'C89'
    a.superclass.should == ClassRegistry['Object']
    b.klass.path.should == 'Class'
    b.path.should == 'CPP'
    b.superclass.should == a
  end

  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # sexp = [:program,
  #         [[:module, [:const_ref, [:@const, "WWD", [1, 7]]],
  #           [:bodystmt, [[:void_stmt]], nil, nil, nil]],
  #          [:class,
  #           [:const_path_ref, [:var_ref, [:@const, "WWD", [1, 23]]],
  #             [:@const, "SuperModule", [1, 28]]],
  #           [:var_ref, [:@const, "Module", [1, 42]]],
  #           [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]
  it 'declares classes inside modules with path-based definitions' do
    tree = Sexp.new(Ripper.sexp('module WWD; end; class WWD::SuperModule < Module; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    wwd_header = list[0][1]
    wwd_body = list[0][2]
    supermod_header = list[1][1]
    supermod_body = list[1][3]
    wwd, supermod = wwd_body.scope.self_ptr, supermod_body.scope.self_ptr
    
    [wwd_body, supermod_body].each { |x| x.scope.should be_a(ClosedScope) }
    wwd_header.scope.should == Scope::GlobalScope
    wwd.klass.path.should == 'Module'
    wwd.path.should == 'WWD'
    supermod.klass.path.should == 'Class'
    supermod.path.should == 'WWD::SuperModule'
    supermod.superclass.should == ClassRegistry['Module']
  end
  
  # [:program,
  #  [[:class,
  #    [:const_ref, [:@const, "Alpha", [1, 6]]],
  #    nil,
  #    [:bodystmt,
  #     [[:def,
  #       [:@ident, "do_xyz", [1, 17]],
  #       [:paren,
  #        [:params,
  #         [[:@ident, "a", [1, 24]]],
  #         [[[:@ident, "b", [1, 27]], [:var_ref, [:@ident, "a", [1, 29]]]]],
  #         nil, nil, nil]],
  #       [:bodystmt,
  #        [[:void_stmt],
  #         [:command,
  #          [:@ident, "p", [1, 33]],
  #          [:args_add_block, [[:var_ref, [:@ident, "b", [1, 35]]]], false]]],
  #        nil, nil, nil]]],
  #     nil, nil, nil]],
  #   [:class,
  #    [:const_ref, [:@const, "B22", [1, 54]]],
  #    [:var_ref, [:@const, "Alpha", [1, 60]]],
  #    [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]
  it 'defines methods on the current Class, which are inherited' do
    tree = Sexp.new(Ripper.sexp('class Alpha; def do_xyz(a, b=a); p b; end; end; class B22 < Alpha; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0][3][1][0]
    body = definition[3]
    [body, *body.all_subtrees].each do |node|
      new_scope = node.scope
      new_scope.self_ptr.should be_a(LaserObject)
      new_scope.self_ptr.klass.should == ClassRegistry['Alpha']
      new_scope.locals.should_not be_empty
      new_scope.lookup('a').should == Bindings::ArgumentBinding.new('a', LaserObject.new, :positional)
      new_scope.lookup('b').should == Bindings::ArgumentBinding.new(
          'b', LaserObject.new, :optional,
          Sexp.new([:var_ref, [:@ident, "a", [1, 29]]]))
    end
    # now make sure the method got created in the M13 module!
    ['Alpha', 'B22'].each do |klass|
      method = ClassRegistry[klass].instance_methods['do_xyz']
      method.should_not be_nil
      method.signatures.size.should == 1
      signature = method.signatures.first
      signature.arguments.should == [body.scope.lookup('a'), body.scope.lookup('b')]
      signature.name.should == 'do_xyz'
    end
  end

  # [:program,
  #  [[:def,
  #    [:@ident, "abc", [1, 4]],
  #    [:paren,
  #     [:params,
  #      [[:@ident, "bar", [1, 8]]],
  #      nil, nil, nil,
  #      [:blockarg, [:@ident, "blk", [1, 14]]]]],
  #    [:bodystmt,
  #     [[:void_stmt],
  #      [:command,
  #       [:@ident, "p", [1, 20]],
  #       [:args_add_block, [[:var_ref, [:@ident, "blk", [1, 22]]]], false]]],
  #     nil, nil, nil]]]]
  it 'defines method on the main object, if no scope is otherwise enclosing a method definition' do
    tree = Sexp.new(Ripper.sexp('def abc(bar, &blk); p blk; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0]
    body = definition[3]
    [body, *body.all_subtrees].each do |node|
      new_scope = node.scope
      new_scope.self_ptr.name.should == 'main'
      new_scope.self_ptr.should be_a(LaserObject)
      new_scope.self_ptr.klass.should == ClassRegistry['Object']
      new_scope.locals.should_not be_empty
      new_scope.lookup('bar').should == Bindings::ArgumentBinding.new('bar', LaserObject.new, :positional)
      new_scope.lookup('blk').should == Bindings::ArgumentBinding.new('blk', ClassRegistry['Proc'], :block)
    end
    method = Scope::GlobalScope.self_ptr.singleton_class.instance_methods['abc']
    method.should_not be_nil
    method.signatures.size.should == 1
    signature = method.signatures.first
    signature.arguments.should == [body.scope.lookup('bar'), body.scope.lookup('blk')]
    signature.name.should == 'abc'
  end
  
  # [:program,
  # [[:defs,
  #   [:var_ref, [:@kw, "self", [1, 4]]],
  #   [:@period, ".", [1, 8]],
  #   [:@ident, "abc", [1, 9]],
  #   [:paren,
  #    [:params,
  #     [[:@ident, "bar", [1, 13]]],
  #     nil, nil, nil,
  #     [:blockarg, [:@ident, "blk", [1, 19]]]]],
  #   [:bodystmt,
  #    [[:void_stmt],
  #     [:command,
  #      [:@ident, "p", [1, 25]],
  #      [:args_add_block, [[:var_ref, [:@ident, "blk", [1, 27]]]], false]]],
  #    nil, nil, nil]]]]
  it 'defines singleton methods on the main object, if no scope is otherwise enclosing a method definition' do
    tree = Sexp.new(Ripper.sexp('def self.abcd(bar, &blk); p blk; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0]
    body = definition[5]
    [body, *body.all_subtrees].each do |node|
      new_scope = node.scope
      new_scope.self_ptr.name.should == 'main'
      new_scope.self_ptr.should be_a(LaserObject)
      new_scope.self_ptr.klass.should == ClassRegistry['Object']
      new_scope.locals.should_not be_empty
      new_scope.lookup('bar').should == Bindings::ArgumentBinding.new('bar', LaserObject.new, :positional)
      new_scope.lookup('blk').should == Bindings::ArgumentBinding.new('blk', ClassRegistry['Proc'], :block)
    end
    method = Scope::GlobalScope.self_ptr.singleton_class.instance_methods['abcd']
    method.should_not be_nil
    method.signatures.size.should == 1
    signature = method.signatures.first
    signature.arguments.should == [body.scope.lookup('bar'), body.scope.lookup('blk')]
    signature.name.should == 'abcd'
  end
  
  # [:program,
  #  [[:def,
  #    [:@ident, "abc", [1, 4]],
  #    [:paren,
  #     [:params,
  #      [[:@ident, "bar", [1, 8]]], nil, nil, nil,
  #      [:blockarg, [:@ident, "blk", [1, 14]]]]],
  #    [:bodystmt,
  #     [[:void_stmt],
  #      [:command,
  #       [:@ident, "p", [1, 20]],
  #       [:args_add_block, [[:var_ref, [:@ident, "blk", [1, 22]]]], false]],
  #      [:assign,
  #       [:var_field, [:@ident, "a", [1, 27]]],
  #       [:var_ref, [:@ident, "bar", [1, 31]]]],
  #      [:assign,
  #       [:var_field, [:@ident, "z", [1, 36]]],
  #       [:var_ref, [:@ident, "a", [1, 40]]]]],
  #     nil, nil, nil]]]]
  it 'creates new scopes on single assignments' do
    tree = Sexp.new(Ripper.sexp('def abc(bar, &blk); p blk; a = bar; z = a; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0]
    body = definition[3]
    body_def = body[1][1..-1]

    body_def[0].should_not see_var('a')
    body_def[1].scope.lookup('a').should be_a(Bindings::LocalVariableBinding)
    body_def[1].should_not see_var('z')
    body_def[2].scope.lookup('z').should be_a(Bindings::LocalVariableBinding)
    body_def[2].scope.lookup('a').should be_a(Bindings::LocalVariableBinding)
    
    body_def[2].scope.should_not == body_def[1].scope
  end
  
  # [:program,
  #  [[:def,
  #    [:@ident, "abc", [1, 4]],
  #    [:paren,
  #     [:params,
  #      [[:@ident, "bar", [1, 8]]], nil, nil, nil,
  #      [:blockarg, [:@ident, "blk", [1, 14]]]]],
  #    [:bodystmt,
  #     [[:void_stmt],
  #      [:command,
  #       [:@ident, "p", [1, 20]],
  #       [:args_add_block, [[:var_ref, [:@ident, "blk", [1, 22]]]], false]],
  #      [:assign,
  #       [:var_field, [:@ident, "a", [1, 27]]],
  #       [:var_ref, [:@ident, "bar", [1, 31]]]],
  #      [:assign,
  #       [:var_field, [:@ident, "a", [1, 36]]],
  #       [:var_ref, [:@ident, "blk", [1, 40]]]]],
  #     nil, nil, nil]]]]
  it 'does not create new scopes when re-using a binding' do
    tree = Sexp.new(Ripper.sexp('def abc(bar, &blk); p blk; a = bar; a = blk; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0]
    body = definition[3]
    body_def = body[1][1..-1]

    body_def[0].should_not see_var('a')
    body_def[1].should see_var('a')
    body_def[2].should see_var('a')
    body_def[1].scope.lookup('a').should be_a(Bindings::LocalVariableBinding)
    body_def[2].scope.lookup('a').should be_a(Bindings::LocalVariableBinding)
    
    body_def[2].scope.object_id.should == body_def[1].scope.object_id
    body_def[1].scope.lookup('a').object_id.should == body_def[2].scope.lookup('a').object_id
  end
  
  # [:program,
  #  [[:module,
  #    [:const_ref, [:@const, "TestA", [1, 7]]],
  #    [:bodystmt,
  #     [[:void_stmt],
  #      [:assign,
  #       [:var_field, [:@const, "PI", [1, 14]]],
  #       [:@float, "3.14", [1, 19]]],
  #      [:assign,
  #       [:var_field, [:@const, "TAU", [1, 25]]],
  #       [:binary,
  #        [:var_ref, [:@const, "PI", [1, 31]]],
  #        :*,
  #        [:@int, "2", [1, 36]]]]],
  #     nil, nil, nil]]]]
  it 'creates new scopes as new constants are assigned to' do
    tree = Sexp.new(Ripper.sexp('module TestA; PI = 3.14; TAU = PI * 2; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    body = tree[1][0][2][1]
    
    body[0].should_not see_var('PI')
    body[0].should_not see_var('TAU')
    body[1].should see_var('PI')
    body[1].should_not see_var('TAU')
    body[2].should see_var('PI')
    body[2].should see_var('TAU')
    
    body[1].scope.lookup('PI').should be_a(Bindings::ConstantBinding)
    body[2].scope.lookup('TAU').should be_a(Bindings::ConstantBinding)

    body[1].scope.object_id.should_not == body[2].scope.object_id
  end
  
  # [:program,
  #  [[:module,
  #    [:const_ref, [:@const, "TestA", [1, 7]]],
  #    [:bodystmt,
  #     [[:void_stmt],
  #      [:assign,
  #       [:var_field, [:@const, "PI", [1, 14]]],
  #       [:@float, "3.14", [1, 19]]],
  #      [:assign,
  #       [:var_field, [:@gvar, "$TEST_TAU", [1, 25]]],
  #       [:binary,
  #        [:var_ref, [:@const, "PI", [1, 37]]],
  #        :*,
  #        [:@int, "2", [1, 42]]]]],
  #     nil, nil, nil]]]]
  it 'creates global variable bindings when discovered' do
    tree = Sexp.new(Ripper.sexp('module TestA; PI = 3.14; $TEST_TAU = PI * 2; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    
    # just by annotating this, the new gvar should've been discovered.
    Scope::GlobalScope.lookup('$TEST_TAU').should be_a(Bindings::GlobalVariableBinding)
    body = tree[1][0][2][1]
    body[1].should see_var('PI')
    # and this is why dynamic scoping is bad:
    body[1].should see_var('$TEST_TAU')
  end
  
  # [:program,
  # [[:command,
  #   [:@ident, "p", [1, 0]],
  #   [:args_add_block, [[:var_ref, [:@kw, "nil", [1, 2]]]], false]],
  #  [:massign,
  #   [[:@ident, "a", [1, 7]],
  #    [:mlhs_paren,
  #     [:mlhs_add_star,
  #      [[:@const, "Z", [1, 11]],
  #       [:mlhs_paren,
  #        [[:mlhs_paren,
  #          [[:@ivar, "@b", [1, 16]],
  #           [:@gvar, "$f", [1, 20]],
  #           [:@cvar, "@@j", [1, 24]]]],
  #         [:mlhs_paren, [[:@ident, "i", [1, 31]], [:@ident, "p", [1, 34]]]]]]],
  #      [:@ident, "d", [1, 40]]]],
  #    [:@ident, "c", [1, 44]]],
  #   [:mrhs_new_from_args, [[:@int, "1", [1, 48]]], [:@int, "2", [1, 51]]]],
  #  [:command,
  #   [:@ident, "p", [1, 54]],
  #   [:args_add_block, [[:var_ref, [:@ident, "c", [1, 56]]]], false]]]]
  
  it 'creates multiple bindings all at once during multiple assignments' do
    tree = Sexp.new(Ripper.sexp('p nil; a, (Z, ((b, $f, j), (i, p)), *d), c = 1, 2; p c'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    
    list = tree[1]
    %w(a Z b j i p d c).each do |var|
      list[0].should_not see_var(var)
      list[1].should see_var(var)
      list[2].should see_var(var)
    end
    list[0].should see_var('$f')
    list[1].should see_var('$f')
  end
  
  # [:program,
  #  [[:command,
  #    [:@ident, "p", [1, 0]],
  #    [:args_add_block, [[:var_ref, [:@kw, "nil", [1, 2]]]], false]],
  #   [:for,
  #    [:var_field, [:@ident, "x", [1, 11]]],
  #    [:array, nil],
  #    [[:command,
  #      [:@ident, "p", [1, 20]],
  #      [:args_add_block, [[:var_ref, [:@ident, "x", [1, 22]]]], false]]]]]]
  it 'creates a single binding with a simple for loop' do
    tree = Sexp.new(Ripper.sexp('p nil; for x in []; p x; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    list[0].should_not see_var('x')

    forloop = list[1]
    forloop.should see_var('x')
    forloop[3].should see_var('x')
  end
  
  # [:program,
  #  [[:command,
  #    [:@ident, "p", [1, 0]],
  #    [:args_add_block, [[:var_ref, [:@kw, "nil", [1, 2]]]], false]],
  #   [:for,
  #    [[:@const, "A92", [1, 11]],
  #     [:@ident, "x", [1, 16]],
  #     [:mlhs_paren,
  #      [[:@ident, "y", [1, 20]],
  #       [:mlhs_paren, [[:@ident, "z", [1, 24]], [:@gvar, "$f", [1, 27]]]]]]],
  #    [:array, nil],
  #    [[:command,
  #      [:@ident, "p", [1, 39]],
  #      [:args_add_block, [[:var_ref, [:@ident, "x", [1, 41]]]], false]]]]]]
  it 'creates many bindings with a complex for loop initializer' do
    tree = Sexp.new(Ripper.sexp('p nil; for A92, x, (y, (z, $f)) in []; p x; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    list[0].should_not see_var('A92')
    list[0].should_not see_var('x')
    list[0].should_not see_var('y')
    list[0].should_not see_var('z')
    list[0].should see_var('$f')

    forloop = list[1]
    forloop.should see_var('A92')
    forloop.should see_var('x')
    forloop.should see_var('y')
    forloop.should see_var('z')
    forloop.should see_var('$f')
  end
  
  # [:program,
  # [[:command,
  #   [:@ident, "p", [1, 0]],
  #   [:args_add_block, [[:var_ref, [:@kw, "nil", [1, 2]]]], false]],
  #  [:method_add_block,
  #   [:method_add_arg,
  #    [:call,
  #     [:array, [[:@int, "1", [1, 8]], [:@int, "2", [1, 10]]]],
  #     :".",
  #     [:@ident, "crazy_blocker", [1, 13]]],
  #    [:arg_paren,
  #     [:args_add_block,
  #      [[:@int, "2", [1, 27]], [:@int, "5", [1, 29]]],
  #      false]]],
  #   [:do_block,
  #    [:block_var,
  #     [:params,
  #      [[:@ident, "x", [1, 36]]],
  #      [[[:@ident, "y", [1, 39]], [:var_ref, [:@ident, "x", [1, 41]]]]],
  #      [:rest_param, [:@ident, "rest", [1, 45]]],
  #      nil,
  #      [:blockarg, [:@ident, "blk", [1, 52]]]],
  #     nil],
  #    [[:void_stmt],
  #     [:command,
  #      [:@ident, "p", [1, 58]],
  #      [:args_add_block, [[:var_ref, [:@ident, "x", [1, 60]]]], false]]]]]]]
  it 'creates a new open scope when a block is used' do
    tree = Sexp.new(Ripper.sexp('p nil; [1,2].crazy_blocker(2,5) do |x, y=x, *rest, &blk|; p x; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    list[0].should_not see_var('x')
    list[0].should_not see_var('y')
    list[0].should_not see_var('rest')
    list[0].should_not see_var('blk')

    block_body = list[1][2][2]
    block_body.scope.should be_a(OpenScope)
    block_body.should see_var('x')
    block_body.should see_var('y')
    block_body.should see_var('rest')
    block_body.should see_var('blk')
  end
  
  
  # [:program,
  # [[:assign, [:var_field, [:@ident, "z", [1, 0]]], [:@int, "10", [1, 4]]],
  #  [:method_add_block,
  #   [:method_add_arg,
  #    [:call,
  #     [:array, [[:@int, "1", [1, 9]], [:@int, "2", [1, 11]]]],
  #     :".",
  #     [:@ident, "crazy_blocker", [1, 14]]],
  #    [:arg_paren,
  #     [:args_add_block,
  #      [[:@int, "2", [1, 28]], [:@int, "5", [1, 30]]],
  #      false]]],
  #   [:do_block,
  #    [:block_var,
  #     [:params,
  #      [[:@ident, "x", [1, 37]]],
  #      [[[:@ident, "y", [1, 40]], [:var_ref, [:@ident, "x", [1, 42]]]]],
  #      nil, nil, nil],
  #     nil],
  #    [[:void_stmt],
  #     [:command,
  #      [:@ident, "p", [1, 46]],
  #      [:args_add_block, [[:var_ref, [:@ident, "x", [1, 48]]]], false]]]]]]]
  it 'creates a scope that can reference parent scope variables when a block is found' do
    tree = Sexp.new(Ripper.sexp('z = 10; [1,2].crazy_blocker(2,5) do |x, y=x|; p x; end'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    list[0].should see_var('z')
    list[0].should_not see_var('x')
    list[0].should_not see_var('y')

    block_body = list[1][2][2]
    block_body.should see_var('z')
    block_body.should see_var('x')
    block_body.should see_var('y')
  end
  
  # [:program,
  #  [[:assign, [:var_field, [:@ident, "z", [1, 0]]], [:@int, "10", [1, 4]]],
  #   [:method_add_block,
  #    [:call, [:array, nil], :".", [:@ident, "each", [1, 11]]],
  #    [:brace_block,
  #     [:block_var,
  #      [:params,
  #       [[:@ident, "x", [1, 19]]],
  #       [[[:@ident, "y", [1, 22]], [:var_ref, [:@ident, "x", [1, 24]]]]],
  #       nil, nil, nil],
  #      nil],
  #     [[:method_add_block,
  #       [:call,
  #        [:var_ref, [:@ident, "x", [1, 27]]],
  #        :".",
  #        [:@ident, "each", [1, 29]]],
  #       [:brace_block,
  #        [:block_var,
  #         [:params,
  #          [[:@ident, "abc", [1, 37]], [:@ident, "jkl", [1, 42]]],
  #          nil, nil, nil, nil],
  #         nil],
  #        [[:method_add_block,
  #          [:call,
  #           [:var_ref, [:@ident, "abc", [1, 47]]],
  #           :".",
  #           [:@ident, "each", [1, 51]]],
  #          [:brace_block,
  #           [:block_var,
  #            [:params, [[:@ident, "oo", [1, 59]]], nil, nil, nil, nil],
  #            nil],
  #           [[:var_ref, [:@ident, "oo", [1, 63]]]]]]]]]]]]]]
  it 'handles deep block nesting' do
    tree = Sexp.new(Ripper.sexp('z = 10; [].each { |x, y=x| x.each { |abc, jkl| abc.each { |oo| oo }}}'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    list[0].should see_var('z')
    list[0].should_not see_var('x')
    list[0].should_not see_var('y')

    first_block_body = list[1][2][2]
    first_block_body.should see_var('z')
    first_block_body.should see_var('x')
    first_block_body.should see_var('y')
    first_block_body.should_not see_var('abc')
    first_block_body.should_not see_var('jkl')
    first_block_body.should_not see_var('oo')
    
    second_block_body = first_block_body[0][2][2]
    second_block_body.should see_var('z')
    second_block_body.should see_var('x')
    second_block_body.should see_var('y')
    second_block_body.should see_var('abc')
    second_block_body.should see_var('jkl')
    second_block_body.should_not see_var('oo')
    
    third_block_body = second_block_body[0][2][2]
    third_block_body.should see_var('z')
    third_block_body.should see_var('x')
    third_block_body.should see_var('y')
    third_block_body.should see_var('abc')
    third_block_body.should see_var('jkl')
    third_block_body.should see_var('oo')
    
    third_block_body.scope.lookup('z').should be list[0].scope.lookup('z')
  end
  
  # [:program,
  #  [[:assign, [:var_field, [:@ident, "x", [1, 0]]], [:@int, "10", [1, 4]]],
  #   [:method_add_block,
  #    [:call, [:array, nil], :".", [:@ident, "each", [1, 11]]],
  #    [:brace_block,
  #     [:block_var,
  #      [:params,
  #       [[:@ident, "x", [1, 19]]],
  #       [[[:@ident, "y", [1, 22]], [:var_ref, [:@ident, "x", [1, 24]]]]],
  #       nil,
  #       nil,
  #       nil],
  #      nil],
  #     [[:var_ref, [:@ident, "y", [1, 27]]]]]]]]
  it 'handles block variables shadowing outside variables' do
    tree = Sexp.new(Ripper.sexp('x = 10; [].each { |x, y=x| y }'))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    list[0].should see_var('x')
    list[0].should_not see_var('y')

    first_block_body = list[1][2][2]
    first_block_body.should see_var('x')
    first_block_body.should see_var('y')
    
    first_block_body.scope.lookup('x').should_not be list[0].scope.lookup('x')
  end
end
  
describe 'complete tests' do
  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # sexp = 
  # [:program,
  #  [[:module,
  #    [:const_ref, [:@const, "And", [1, 7]]],
  #    [:bodystmt,
  #     [[:void_stmt],
  #      [:module,
  #       [:const_ref, [:@const, "Or", [2, 9]]],
  #       [:bodystmt,
  #        [[:void_stmt],
  #         [:module,
  #          [:const_ref, [:@const, "Is", [3, 11]]],
  #          [:bodystmt,
  #           [[:void_stmt],
  #            [:module,
  #             [:const_ref, [:@const, "Ten", [4, 13]]],
  #             [:bodystmt,
  #              [[:void_stmt],
  #               [:module,
  #                [:const_ref, [:@const, "Seven", [5, 15]]],
  #                [:bodystmt, [[:void_stmt]], nil, nil, nil]]],
  #              nil, nil, nil]]],
  #           nil, nil, nil]]],
  #        nil, nil, nil]]],
  #     nil, nil, nil]],
  #   [:module,
  #    [:const_ref, [:@const, "And", [11, 7]]],
  #    [:bodystmt,
  #     [[:void_stmt],
  #      [:class,
  #       [:const_path_ref,
  #        [:var_ref, [:@const, "Or", [12, 8]]],
  #        [:@const, "Type", [12, 12]]],
  #       nil,
  #       [:bodystmt, [[:void_stmt]], nil, nil, nil]],
  #      [:class,
  #       [:const_path_ref,
  #        [:const_path_ref,
  #         [:const_path_ref,
  #          [:var_ref, [:@const, "Or", [14, 8]]],
  #          [:@const, "Is", [14, 12]]],
  #         [:@const, "Ten", [14, 16]]],
  #        [:@const, "Kind", [14, 21]]],
  #       [:const_path_ref,
  #        [:const_path_ref,
  #         [:top_const_ref, [:@const, "And", [14, 30]]],
  #         [:@const, "Or", [14, 35]]],
  #        [:@const, "Type", [14, 39]]],
  #       [:bodystmt,
  #        [[:module,
  #          [:const_ref, [:@const, "Silly", [15, 11]]],
  #          [:bodystmt, [[:void_stmt]], nil, nil, nil]]],
  #        nil, nil, nil]],
  #      [:module,
  #       [:const_path_ref,
  #        [:const_path_ref,
  #         [:const_path_ref,
  #          [:const_path_ref,
  #           [:var_ref, [:@const, "Or", [18, 9]]],
  #           [:@const, "Is", [18, 13]]],
  #          [:@const, "Ten", [18, 17]]],
  #         [:@const, "Kind", [18, 22]]],
  #        [:@const, "Silly", [18, 28]]],
  #       [:bodystmt, [[:void_stmt]], nil, nil, nil]]],
  #     nil, nil, nil]]]]
  
  it 'handles a monstrous comprehensive module and class nesting example' do
    tree = Sexp.new(Ripper.sexp(<<-EOF
module And
  module Or
    module Is
      module Ten
        module Seven
        end
      end
    end
  end
end
module And
  class Or::Type
  end
  class Or::Is::Ten::Kind < ::And::Or::Type
    module Silly
    end
  end
  module Or::Is::Ten::Kind::Silly
  end
end
EOF
))
    ExpandedIdentifierAnnotation::Annotator.new.annotate!(tree)
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    and_header, and_body = list[0][1..2]
    or_body = and_body[1][1][2]
    is_body = or_body[1][1][2]
    and_mod, or_mod, is_mod = [and_body, or_body, is_body].map {|node| node.scope.self_ptr }
    and_header.scope.self_ptr.name.should == 'main'
    and_mod.path.should == 'And'
    or_mod.path.should == 'And::Or'
    is_mod.path.should == 'And::Or::Is'
    reopen_and_body = list[1][2]
    type_body = reopen_and_body[1][1][3]
    kind_body = reopen_and_body[1][2][3]
    silly_body = reopen_and_body[1][3][2]
    reopen_and_mod, type_class, kind_class, silly_mod =
        [reopen_and_body, type_body, kind_body, silly_body].map do |node|
      node.scope.self_ptr
    end
    reopen_and_mod.path.should == 'And'
    reopen_and_mod.object_id.should == and_mod.object_id
    type_class.path.should == 'And::Or::Type'
    kind_class.path.should == 'And::Or::Is::Ten::Kind'
    kind_class.superclass.path.should == 'And::Or::Type'
    silly_mod.path.should == 'And::Or::Is::Ten::Kind::Silly'
  end
end