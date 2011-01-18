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
    temp_mod = WoolModule.new('ABC', temp_scope)
    tree = Sexp.new(Ripper.sexp('p 5; module ABC::DEF; end'))
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
    temp_mod = WoolModule.new('A10', temp_scope)
    tree = Sexp.new(Ripper.sexp('module A10::B12; end; module A10::B12; end'))
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
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0][2][1][1]
    body = definition[3]
    [body, *body.all_subtrees].each do |node|
      new_scope = node.scope
      new_scope.self_ptr.should be_a(WoolObject)
      new_scope.self_ptr.klass.should == ClassRegistry['M13']
      new_scope.locals.should_not be_empty
      new_scope.lookup('rest').should == Bindings::ArgumentBinding.new('rest', WoolObject.new(ClassRegistry['Array']), :rest)
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
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0][2][1][1]
    body = definition[5]
    [body, *body.all_subtrees].each do |node|
      new_scope = node.scope
      new_scope.self_ptr.should be_a(WoolModule)
      new_scope.self_ptr.should == ClassRegistry['M49']
      new_scope.self_ptr.klass.should == ClassRegistry['Module']
      new_scope.locals.should_not be_empty
      new_scope.lookup('a').should == Bindings::ArgumentBinding.new('a', WoolObject.new, :positional)
      new_scope.lookup('b').should == Bindings::ArgumentBinding.new(
          'b', WoolObject.new, :optional,
          Sexp.new([:var_ref, [:@ident, "a", [1, 32]]]))
    end
    
    method = ClassRegistry['M49'].singleton_class.instance_methods['silly']
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
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0][3][1][0]
    body = definition[3]
    [body, *body.all_subtrees].each do |node|
      new_scope = node.scope
      new_scope.self_ptr.should be_a(WoolObject)
      new_scope.self_ptr.klass.should == ClassRegistry['Alpha']
      new_scope.locals.should_not be_empty
      new_scope.lookup('a').should == Bindings::ArgumentBinding.new('a', WoolObject.new, :positional)
      new_scope.lookup('b').should == Bindings::ArgumentBinding.new(
          'b', WoolObject.new, :optional,
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
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0]
    body = definition[3]
    [body, *body.all_subtrees].each do |node|
      new_scope = node.scope
      new_scope.self_ptr.name.should == 'main'
      new_scope.self_ptr.should be_a(WoolObject)
      new_scope.self_ptr.klass.should == ClassRegistry['Object']
      new_scope.locals.should_not be_empty
      new_scope.lookup('bar').should == Bindings::ArgumentBinding.new('bar', WoolObject.new, :positional)
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
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0]
    body = definition[5]
    [body, *body.all_subtrees].each do |node|
      new_scope = node.scope
      new_scope.self_ptr.name.should == 'main'
      new_scope.self_ptr.should be_a(WoolObject)
      new_scope.self_ptr.klass.should == ClassRegistry['Object']
      new_scope.locals.should_not be_empty
      new_scope.lookup('bar').should == Bindings::ArgumentBinding.new('bar', WoolObject.new, :positional)
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
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0]
    body = definition[3]
    body_def = body[1][1..-1]

    expect { body_def[0].scope.lookup('a') }.to raise_error(Scope::ScopeLookupFailure)
    body_def[1].scope.lookup('a').should be_a(Bindings::LocalVariableBinding)
    expect { body_def[1].scope.lookup('z') }.to raise_error(Scope::ScopeLookupFailure)
    body_def[2].scope.lookup('z').should be_a(Bindings::LocalVariableBinding)
    body_def[2].scope.lookup('a').should be_a(Bindings::LocalVariableBinding)
    
    body_def[2].scope.should_not == body_def[1].scope
  end
  
  it 'does not create new scopes when re-using a binding' do
    tree = Sexp.new(Ripper.sexp('def abc(bar, &blk); p blk; a = bar; a = blk; end'))
    ScopeAnnotation::Annotator.new.annotate!(tree)
    definition = tree[1][0]
    body = definition[3]
    body_def = body[1][1..-1]

    expect { body_def[0].scope.lookup('a') }.to raise_error(Scope::ScopeLookupFailure)
    body_def[1].scope.lookup('a').should be_a(Bindings::LocalVariableBinding)
    body_def[2].scope.lookup('a').should be_a(Bindings::LocalVariableBinding)
    
    body_def[2].scope.object_id.should == body_def[1].scope.object_id
    body_def[1].scope.lookup('a').object_id.should == body_def[2].scope.lookup('a').object_id
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