require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'
describe ScopeAnnotation do
  extend AnalysisHelpers
  clean_registry
  
  it_should_behave_like 'an annotator'
  
  it 'adds the #scope method to Sexp' do
    Sexp.instance_methods.should include(:scope)
  end
  
  it 'adds scopes to each node with a flat example with no new scopes' do
    tree = Sexp.new(Ripper.sexp('p 5; if b; a; end'))
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    list = tree[1]
    with_new_scope = list[1][2], *list[1][2].all_subtrees
    expectalot(scope: { Scope::GlobalScope => [tree, list[0], list[0][1], list[0][2]],
                           Scope::GlobalScope.lookup('A').scope => with_new_scope })

    list[1][2].scope.should be_a(ClosedScope)
    list[1][2].scope.self_ptr.klass.path.should == 'Module'
    list[1][2].scope.self_ptr.path.should == 'A'
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    list = tree[1]
    list[1][2].scope.self_ptr.name.should == 'B'
    list[1][2].scope.should be_a(ClosedScope)

    with_new_scope = list[1][2], *list[1][2].all_subtrees
    expectalot(scope: { Scope::GlobalScope => [tree, list[0], list[0][1], list[0][2]],
                           Scope::GlobalScope.lookup('B').scope => with_new_scope })
    tree.all_errors.should be_empty
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
    temp_mod = LaserModule.new(ClassRegistry['Module'], temp_scope, 'ABC')
    tree = Sexp.new(Ripper.sexp('p 5; module ABC::DEF; end'))
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
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
    tree.all_errors.should be_empty
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
    temp_mod = LaserModule.new(ClassRegistry['Module'], temp_scope, 'A10')
    tree = Sexp.new(Ripper.sexp('module A10::B12; end; module A10::B12; end'))
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
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
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
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
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
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
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
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
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
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
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
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
    tree.all_errors.should be_empty
  end
  
  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # sexp = [:program, [
  #         [:class, [:const_ref, [:@const, "A", [1, 6]]], nil,
  #           [:bodystmt, [[:void_stmt]], nil, nil, nil]]]]
  it 'creates a new scope when a class declaration is encountered' do
    tree = Sexp.new(Ripper.sexp('class C99; end'))
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    list = tree[1]
    a_header = list[0][1]
    a_body = list[0][3]
    a_body.scope.should be_a(ClosedScope)
    a = a_body.scope.self_ptr
    
    a_header.scope.should == Scope::GlobalScope
    a.klass.path.should == 'Class'
    a.path.should == 'C99'
    a.superclass.should == ClassRegistry['Object']
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
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
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
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
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
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
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
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
    method.visibility.should == :private
    method.signatures.size.should == 1
    signature = method.signatures.first
    signature.arguments.should == [body.scope.lookup('bar'), body.scope.lookup('blk')]
    signature.name.should == 'abc'
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
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
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    definition = tree[1][0]
    body = definition[3]
    body_def = body[1][1..-1]

    body_def[1].scope.lookup('a').should be_a(Bindings::LocalVariableBinding)
    body_def[2].scope.lookup('z').should be_a(Bindings::LocalVariableBinding)
    body_def[2].scope.lookup('a').should be_a(Bindings::LocalVariableBinding)
    
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    definition = tree[1][0]
    body = definition[3]
    body_def = body[1][1..-1]

    body_def[1].should see_var('a')
    body_def[2].should see_var('a')
    body_def[1].scope.lookup('a').should be_a(Bindings::LocalVariableBinding)
    body_def[2].scope.lookup('a').should be_a(Bindings::LocalVariableBinding)
    
    body_def[2].scope.object_id.should == body_def[1].scope.object_id
    body_def[1].scope.lookup('a').object_id.should == body_def[2].scope.lookup('a').object_id
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    body = tree[1][0][2][1]
    
    body[2].should see_var('PI')
    body[2].should see_var('TAU')
    
    body[1].scope.lookup('PI').should be_a(Bindings::ConstantBinding)
    body[2].scope.lookup('TAU').should be_a(Bindings::ConstantBinding)
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
    # just by annotating this, the new gvar should've been discovered.
    Scope::GlobalScope.lookup('$TEST_TAU').should be_a(Bindings::GlobalVariableBinding)
    body = tree[1][0][2][1]
    body[1].should see_var('PI')
    # and this is why dynamic scoping is bad:
    body[1].should see_var('$TEST_TAU')
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
    list = tree[1]
    %w(a Z b j i p d c).each do |var|
      list[1].should see_var(var)
      list[2].should see_var(var)
    end
    list[0].should see_var('$f')
    list[1].should see_var('$f')
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    list = tree[1]

    forloop = list[1]
    forloop.should see_var('x')
    forloop[3].should see_var('x')
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    list = tree[1]
    list[0].should see_var('$f')

    forloop = list[1]
    forloop.should see_var('A92')
    forloop.should see_var('x')
    forloop.should see_var('y')
    forloop.should see_var('z')
    forloop.should see_var('$f')
    tree.all_errors.should_not be_empty
    tree.all_errors.first.should be_a(ScopeAnnotation::ConstantInForLoopError)
    tree.all_errors.first.message.should include('A92')
  end
  
  it 'creates an error for each constant named as a for loop variable' do
    consts = %w(A99 B99 C99 D99)
    tree = Sexp.new(Ripper.sexp("for #{consts.join(', ')} in []; p A99; end"))
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
    tree.all_errors.size.should == 4
    consts.each_with_index do |const, idx|
      tree.all_errors[idx].should be_a(ScopeAnnotation::ConstantInForLoopError)
      tree.all_errors[idx].message.should include(const)
    end
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    list = tree[1]

    block_body = list[1][2][2]
    block_body.scope.should be_a(OpenScope)
    block_body.should see_var('x')
    block_body.should see_var('y')
    block_body.should see_var('rest')
    block_body.should see_var('blk')
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    list = tree[1]
    list[0].should see_var('z')

    block_body = list[1][2][2]
    block_body.should see_var('z')
    block_body.should see_var('x')
    block_body.should see_var('y')
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    list = tree[1]
    list[0].should see_var('z')

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
    tree.all_errors.should be_empty
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    list = tree[1]
    list[0].should see_var('x')

    first_block_body = list[1][2][2]
    first_block_body.should see_var('x')
    first_block_body.should see_var('y')
    
    first_block_body.scope.lookup('x').should_not be list[0].scope.lookup('x')
    tree.all_errors.should be_empty
  end
  
  it 'handles blocks with *no* variables' do
    tree = Sexp.new(Ripper.sexp('x = 10; [].each { x }'))
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    list = tree[1]
    list[0].should see_var('x')

    first_block_body = list[1][2][2]
    first_block_body.should see_var('x')
    
    tree.all_errors.should be_empty
  end
  
  it 'handles module inclusions done in the typical method-call fashion' do
    input = 'module A113; end; module B113; end; class C113; include A113, B113; end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
    c113 = ClassRegistry['C113']
    c113.should_not be nil
    c113.ancestors.should == [ClassRegistry['C113'], ClassRegistry['A113'], ClassRegistry['B113'],
                              ClassRegistry['Object'], ClassRegistry['Kernel']]
                              
    tree.all_errors.should be_empty
  end
  
  it 'handles complex module/class hierarchies' do
    input = "module A114; end; module B114; include A114; end; module C114; include B114; end\n" +
            "class X114; include A114; end; class Y114 < X114; include C114; end"
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
    ClassRegistry['A114'].ancestors.should == [ClassRegistry['A114']]
    ClassRegistry['B114'].ancestors.should == [ClassRegistry['B114'], ClassRegistry['A114']]
    ClassRegistry['C114'].ancestors.should == [ClassRegistry['C114'], ClassRegistry['B114'], ClassRegistry['A114']]
    
    ClassRegistry['X114'].ancestors.should == [ClassRegistry['X114'], ClassRegistry['A114'], ClassRegistry['Object'],
                                               ClassRegistry['Kernel']]
    ClassRegistry['Y114'].ancestors.should == [ClassRegistry['Y114'], ClassRegistry['C114'], ClassRegistry['B114'],
                                               ClassRegistry['X114'], ClassRegistry['A114'], ClassRegistry['Object'],
                                               ClassRegistry['Kernel']]
    tree.all_errors.should be_empty
  end
  
  it 'generates an error when a class is re-opened as a module' do
    input = "class A115; end; module A115; end"
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
    tree[1][1].errors.should_not be_empty
    tree[1][1].errors.first.should be_a(ScopeAnnotation::ReopenedClassAsModuleError)
  end
  
  it 'generates an error when a module is re-opened as a class' do
    input = "module A116; end; class A116; end"
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
    tree[1][1].errors.should_not be_empty
    tree[1][1].errors.first.should be_a(ScopeAnnotation::ReopenedModuleAsClassError)
  end
  
  it 'handles module inclusions done in the parenthesized method-call fashion' do
    input = 'module A117; end; module B117; end; class C117; include(A117, B117); end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
    c117 = ClassRegistry['C117']
    c117.should_not be nil
    c117.ancestors.should == [ClassRegistry['C117'], ClassRegistry['A117'], ClassRegistry['B117'],
                              ClassRegistry['Object'], ClassRegistry['Kernel']]
    tree.all_errors.should be_empty
  end
  
  it 'handles module extensions done in the typical method-call fashion' do
    input = 'module A118; end; module B118; end; class C118; extend A118, B118; end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
    c118 = ClassRegistry['C118']
    c118.should_not be nil
    c118.singleton_class.ancestors.should == [ClassRegistry['C118'].singleton_class,
                                              ClassRegistry['A118'], ClassRegistry['B118'],
                                              ClassRegistry['Object'].singleton_class,
                                              ClassRegistry['Class'], ClassRegistry['Module'],
                                              ClassRegistry['Object'], ClassRegistry['Kernel']]
    tree.all_errors.should be_empty
  end

  it 'handles complex module/class extension hierarchies' do
    input = "module A119; end; module B119; extend A119; end; module C119; extend B119; end\n" +
            "class X119; extend A119; end; class Y119 < X119; extend C119; end"
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
    ClassRegistry['A119'].singleton_class.ancestors.should ==
        [ClassRegistry['A119'].singleton_class, ClassRegistry['Module'],
         ClassRegistry['Object'], ClassRegistry['Kernel']]
    ClassRegistry['B119'].singleton_class.ancestors.should ==
        [ClassRegistry['B119'].singleton_class, ClassRegistry['A119'],
         ClassRegistry['Module'], ClassRegistry['Object'], ClassRegistry['Kernel']]
    ClassRegistry['C119'].singleton_class.ancestors.should ==
        [ClassRegistry['C119'].singleton_class, ClassRegistry['B119'],
         ClassRegistry['Module'], ClassRegistry['Object'], ClassRegistry['Kernel']]

    ClassRegistry['X119'].singleton_class.ancestors.should ==
        [ClassRegistry['X119'].singleton_class, ClassRegistry['A119'],
         ClassRegistry['Object'].singleton_class,
         ClassRegistry['Class'], ClassRegistry['Module'],
         ClassRegistry['Object'], ClassRegistry['Kernel']]
    ClassRegistry['Y119'].singleton_class.ancestors.should ==
        [ClassRegistry['Y119'].singleton_class, ClassRegistry['C119'],
         ClassRegistry['X119'].singleton_class, ClassRegistry['A119'],
         ClassRegistry['Object'].singleton_class,
         ClassRegistry['Class'], ClassRegistry['Module'],
         ClassRegistry['Object'], ClassRegistry['Kernel']]
         
    tree.all_errors.should be_empty
  end
  
  it 'handles module extensions done in the parenthesized method-call fashion' do
    input = 'module A120; end; module B120; end; class C120; extend(A120, B120); end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
    c120 = ClassRegistry['C120']
    c120.should_not be nil
    c120.singleton_class.ancestors.should == [ClassRegistry['C120'].singleton_class,
                                              ClassRegistry['A120'], ClassRegistry['B120'],
                                              ClassRegistry['Object'].singleton_class,
                                              ClassRegistry['Class'], ClassRegistry['Module'],
                                              ClassRegistry['Object'], ClassRegistry['Kernel']]
                                              
    tree.all_errors.should be_empty
  end
  
  # [:program,
  #  [[:class,
  #    [:const_ref, [:@const, "A121", [1, 6]]],
  #    nil,
  #    [:bodystmt,
  #     [[:assign, [:var_field, [:@ident, "x", [1, 12]]], [:@int, "10", [1, 16]]],
  #      [:assign,
  #       [:var_field, [:@ident, "y", [1, 20]]],
  #       [:var_ref, [:@ident, "z", [1, 24]]]]],
  #     nil, nil, nil]]]]
  it 'should generate an error if a local variable cannot be found' do
    input = 'class A121; x = 10; y = Z223; end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
    errors = tree.all_errors
    errors.should_not be_empty
    errors[0].should be_a(Scope::ScopeLookupFailure)
    errors[0].query.should == 'Z223'
    errors[0].scope.self_ptr.should == ClassRegistry['A121'].scope.self_ptr
    errors[0].ast_node.should == tree[1][0][3][1][1][2]
    errors[0].ast_node.binding.should == nil
  end
  
  it 'switches to private visibility upon reaching a call to #private in a class/module' do
    input = 'class A122; private; def foobar; end; end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)

    ClassRegistry['A122'].instance_methods['foobar'].visibility.should == :private
  end
  
  it 'does not switch to private visibility if a local variable is called private' do
    input = 'class A123; private = 5; private; def foobar; end; end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)

    ClassRegistry['A123'].instance_methods['foobar'].visibility.should == :public
  end
  
  it 'switches back and forth from public, private, and protected visibility in a class/module' do
    input = 'module A124; def abc; end; private; def foobar; end; protected; def silly; end; private; def priv; end; end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)

    ClassRegistry['A124'].instance_methods['abc'].visibility.should == :public
    ClassRegistry['A124'].instance_methods['foobar'].visibility.should == :private
    ClassRegistry['A124'].instance_methods['silly'].visibility.should == :protected
    ClassRegistry['A124'].instance_methods['priv'].visibility.should == :private
  end
  
  it 'uses a default private scope at the top level but can switch to public and private' do
    input = 'def t11; end; public; def t12; end; private; def t13; end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)

    singleton = Scope::GlobalScope.self_ptr.singleton_class
    singleton.instance_methods['t11'].visibility.should == :private
    singleton.instance_methods['t12'].visibility.should == :public
    singleton.instance_methods['t13'].visibility.should == :private
  end
  
  it 'raises an error if you try to use protected at the top level' do
    input = 'def t14; end; protected; def t15; end; public; def t16; end'
    tree = Sexp.new(Ripper.sexp(input))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)

    tree.all_errors.size.should be 1
    tree.all_errors.first.should be_a(NoSuchMethodError)
    tree.all_errors.first.message.should include('protected')
    
    # recovers by not changing visibility
    singleton = Scope::GlobalScope.self_ptr.singleton_class
    singleton.instance_methods['t14'].visibility.should == :private
    singleton.instance_methods['t15'].visibility.should == :private
    singleton.instance_methods['t16'].visibility.should == :public
  end
  
  it 'can resolve constant aliasing with superclasses' do
    tree = Sexp.new(Ripper.sexp('class Alpha111; end; Beta111 = Alpha111; class B290 < Beta111; end'))
    RuntimeAnnotation.new.annotate!(tree)
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
    
    ClassRegistry['B290'].superclass.should == ClassRegistry['Alpha111']
    
    tree.all_errors.should be_empty
  end
end
  
describe 'complete tests' do
  extend AnalysisHelpers
  clean_registry
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
    ExpandedIdentifierAnnotation.new.annotate!(tree)
    ScopeAnnotation.new.annotate!(tree)
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
    tree.all_errors.should be_empty
  end
  
  describe 'with a real ruby file as input' do
    before do
      @input = %q{
module Laser
  module SexpAnalysis
    module Bindings
      # This class represents a GenericBinding in Ruby. It may have a known protocol (type),
      # class, value (if constant!), and a variety of other details.
      class GenericBinding
        include Comparable
        attr_accessor :name
        attr_reader :value

        def initialize(name, value)
          @name = name
          @value = :uninitialized
          bind!(value)
        end

        def bind!(value)
          if respond_to?(:validate_value)
            validate_value(value)
          end
          @value = value
        end

        def <=>(other)
          self.name <=> other.name
        end

        def scope
          value.scope
        end

        def protocol
          value.protocol
        end

        def class_used
          value.klass
        end

        def to_s
          inspect
        end

        def inspect
          "#<#{self.class.name.split('::').last}: #{name}>"
        end
      end

      class KeywordBinding < GenericBinding
        private :bind!
      end

      # Constants have slightly different properties in their bindings: They shouldn't
      # be rebound. However.... Ruby allows it. It prints a warning when the rebinding
      # happens, but we should be able to detect this statically. Oh, and they can't be
      # bound inside a method. That too is easily detected statically.
      class ConstantBinding < GenericBinding
        # Require an additional force parameter to rebind a Constant. That way, the user
        # can configure whether rebinding counts as a warning or an error.
        def bind!(val, force=false)
          if @value != :uninitialized && !force
            raise TypeError.new('Cannot rebind a constant binding without const_set')
          end
          super(val)
        end
      end

      # We may want to track # of assignments/reads from local vars, so we should subclass
      # GenericBinding for it.
      class LocalVariableBinding < GenericBinding
      end

      # Possible extension ideas:
      # - Initial definition point?
      class GlobalVariableBinding < GenericBinding
      end

      class ArgumentBinding < GenericBinding
        attr_reader :kind, :default_value_sexp
        def initialize(name, value, kind, default_value = nil)
          super(name, value)
          @kind = kind
          @default_value_sexp = default_value
        end
      end
    end
  end
end
}
    end
    
    it 'correctly resolves many bindings, creates new modules and classes, and defines methods' do
      tree = Sexp.new(Ripper.sexp(@input))
      RuntimeAnnotation.new.annotate!(tree)
      ExpandedIdentifierAnnotation.new.annotate!(tree)
      ScopeAnnotation.new.annotate!(tree)
      
      
      bindings_mod = 'Laser::SexpAnalysis::Bindings'
      ClassRegistry['Laser'].should be_a(LaserModule)
      ClassRegistry['Laser::SexpAnalysis'].should be_a(LaserModule)
      ClassRegistry[bindings_mod].should be_a(LaserModule)
      ClassRegistry["#{bindings_mod}::GenericBinding"].should be_a(LaserClass)
      ClassRegistry["#{bindings_mod}::KeywordBinding"].should be_a(LaserClass)
      ClassRegistry["#{bindings_mod}::ConstantBinding"].should be_a(LaserClass)
      ClassRegistry["#{bindings_mod}::LocalVariableBinding"].should be_a(LaserClass)
      ClassRegistry["#{bindings_mod}::GlobalVariableBinding"].should be_a(LaserClass)
      ClassRegistry["#{bindings_mod}::ArgumentBinding"].should be_a(LaserClass)
      
      ClassRegistry["#{bindings_mod}::GenericBinding"].superclass.should be ClassRegistry['Object']
      [ClassRegistry["#{bindings_mod}::KeywordBinding"],
       ClassRegistry["#{bindings_mod}::ConstantBinding"],
       ClassRegistry["#{bindings_mod}::LocalVariableBinding"],
       ClassRegistry["#{bindings_mod}::GlobalVariableBinding"],
       ClassRegistry["#{bindings_mod}::ArgumentBinding"]].each do |subclass|
        subclass.superclass.should be ClassRegistry["#{bindings_mod}::GenericBinding"]
      end
      
      generic = ClassRegistry["#{bindings_mod}::GenericBinding"]
      generic.instance_variables['@name'].should be_a(Bindings::InstanceVariableBinding)
      generic.instance_variables['@value'].should be_a(Bindings::InstanceVariableBinding)
      arg_binding = ClassRegistry["#{bindings_mod}::ArgumentBinding"]
      arg_binding.instance_variables['@name'].should be generic.instance_variables['@name']
      arg_binding.instance_variables['@value'].should be generic.instance_variables['@value']
      arg_binding.instance_variables['@kind'].should be_a(Bindings::InstanceVariableBinding)
      arg_binding.instance_variables['@default_value_sexp'].should be_a(Bindings::InstanceVariableBinding)
      
      arg_binding.ancestors.should == [arg_binding, generic, ClassRegistry['Comparable'],
                                       ClassRegistry['Object'], ClassRegistry['Kernel']]
      
      %w(initialize bind! <=> scope protocol class_used to_s inspect).each do |method|
        generic.instance_methods[method].should_not be_empty
        generic.instance_methods[method].visibility.should == :public
      end
      init_sig = generic.instance_methods['initialize'].signatures.first
      init_sig.arguments.size.should == 2
      init_sig.arguments.map(&:name).should == ['name', 'value']
      
      arg_binding_sig = arg_binding.instance_methods['initialize'].signatures.first
      arg_binding_sig.arguments.size.should == 4
      arg_binding_sig.arguments.map(&:name).should == ['name', 'value', 'kind', 'default_value']
      
      # [:bodystmt,
      #  [[:super,
      #    [:arg_paren,
      #     [:args_add_block,
      #      [[:var_ref, [:@ident, "name", [82, 16]]],
      #       [:var_ref, [:@ident, "value", [82, 22]]]],
      #      false]]],
      #   [:assign,
      #    [:var_field, [:@ivar, "@kind", [83, 10]]],
      #    [:var_ref, [:@ident, "kind", [83, 18]]]],
      #   [:assign,
      #    [:var_field, [:@ivar, "@default_value_sexp", [84, 10]]],
      #    [:var_ref, [:@ident, "default_value", [84, 32]]]]],
      #  nil,
      #  nil,
      #  nil]
      
      arg_init_body = arg_binding.instance_methods['initialize'].body_ast
      # arguments to super
      arg_init_body[1][0][1][1][1][0].binding.should be_a(Bindings::ArgumentBinding)
      arg_init_body[1][0][1][1][1][0].binding.name.should == 'name'
      arg_init_body[1][0][1][1][1][1].binding.should be_a(Bindings::ArgumentBinding)
      arg_init_body[1][0][1][1][1][1].binding.name.should == 'value'
      # first assign
      arg_init_body[1][1][1].binding.should be_a(Bindings::InstanceVariableBinding)
      arg_init_body[1][1][1].binding.name.should == '@kind'
      arg_init_body[1][1][2].binding.should be_a(Bindings::ArgumentBinding)
      arg_init_body[1][1][2].binding.name.should == 'kind'
      # second assign
      arg_init_body[1][2][1].binding.should be_a(Bindings::InstanceVariableBinding)
      arg_init_body[1][2][1].binding.name.should == '@default_value_sexp'
      arg_init_body[1][2][2].binding.should be_a(Bindings::ArgumentBinding)
      arg_init_body[1][2][2].binding.name.should == 'default_value'
    end
  end
end