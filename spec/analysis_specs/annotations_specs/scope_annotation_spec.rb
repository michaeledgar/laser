require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'
describe ScopeAnnotation do
  before(:each) do
    @backup_all = ProtocolRegistry.protocols.dup
    @backup_map = ProtocolRegistry.class_protocols.dup
  end
  
  after(:each) do
    ProtocolRegistry.protocols.replace @backup_all
    ProtocolRegistry.class_protocols.replace @backup_map
  end
  
  it 'adds the #scope method to Sexp' do
    Sexp.instance_methods.should include(:scope)
  end
  
  it 'adds scopes to each node with a flat example with no new scopes' do
    tree = Sexp.new(Ripper.sexp('a = nil; b = a; if b; a; end'))
    ScopeAnnotation::Annotator.new.annotate!(tree)
    all_sexps_in_subtree(tree).each do |node|
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
    tree = Sexp.new(Ripper.sexp('a = nil; module A; a = 10; end'))
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    with_new_scope = list[1][2], *list[1][2].all_subtrees
    expectalot(:scope => { Scope::GlobalScope => [tree, list[0], list[0][1], list[0][2]],
                           Scope::GlobalScope.lookup('A').scope => with_new_scope })

    list[1][2].scope.self_ptr.class_used.path.should == 'Module'
    list[1][2].scope.self_ptr.value.path.should == 'A'
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
    tree = Sexp.new(Ripper.sexp('a = nil; module ::B; a = 10; end'))
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    list[1][2].scope.self_ptr.name.should == 'B'

    with_new_scope = list[1][2], *list[1][2].all_subtrees
    expectalot(:scope => { Scope::GlobalScope => [tree, list[0], list[0][1], list[0][2]],
                           Scope::GlobalScope.lookup('B').scope => with_new_scope })
  end
  
  # This is the AST that Ripper generates for the parsed code. It is
  # provided here because otherwise the test is inscrutable.
  #
  # sexp = [:program,
  #        [[:assign, [:var_field, [:@ident, "a", [1, 0]]], [:var_ref, [:@kw, "nil", [1, 4]]]],
  #         [:module, [:const_path_ref, [:var_ref, [:@const, "ABC", [1, 16]]], [:@const, "B", [1, 21]]],
  #           [:bodystmt, [[:void_stmt], [:assign, [:var_field, [:@ident, "a", [1, 24]]],
  #           [:@int, "10", [1, 28]]]], nil, nil, nil]]]]
  it 'creates a new scope when a pathed module declaration is encountered' do
    temp_scope = Scope.new(Scope::GlobalScope, nil)
    temp_mod = WoolModule.new('ABC', temp_scope)
    tree = Sexp.new(Ripper.sexp('a = nil; module ABC::DEF; a = 10; end'))
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    mod = list[1][2].scope.self_ptr
    #mod.class_used.path.should == 'ABC::DEF'
    mod.class_used.path.should == 'Module'
    mod.value.path.should == 'ABC::DEF'
    mod.name.should == 'DEF'
    mod.scope.parent.self_ptr.name.should == 'ABC'
    
    with_new_scope = list[1][2], *list[1][2].all_subtrees
    expectalot(:scope => { Scope::GlobalScope => [tree, list[0], list[0][1], list[0][2]],
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
    temp_scope = Scope.new(Scope::GlobalScope, nil)
    temp_mod = WoolModule.new('A10', temp_scope)
    tree = Sexp.new(Ripper.sexp('module A10::B12; end; module A10::B12; end'))
    ScopeAnnotation::Annotator.new.annotate!(tree)
    
    list = tree[1]
    with_new_scope = [list[0][2], *list[0][2].all_subtrees] +
                     [list[1][2], *list[1][2].all_subtrees]
    expectalot(:scope => { Scope::GlobalScope => [tree, list[0], list[0][1], list[1][1]],
                           temp_scope.lookup('B12').scope => with_new_scope })

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
  it 'creates a new scope when a pathed module declaration is encountered' do
    tree = Sexp.new(Ripper.sexp('module A; module B; module C; end; end; end'))
    ScopeAnnotation::Annotator.new.annotate!(tree)
    list = tree[1]
    a_body = list[0][2]
    b_body = a_body[1][1][2]
    c_body = b_body[1][1][2]
    a, b, c = [a_body, b_body, c_body].map {|x| x.scope.self_ptr }
    
    a.class_used.path.should == 'Module'
    b.class_used.path.should == 'Module'
    c.class_used.path.should == 'Module'
    a.value.path.should == 'A'
    b.value.path.should == 'A::B'
    c.value.path.should == 'A::B::C'
    a.value.name.should == 'A'
    b.value.name.should == 'B'
    c.value.name.should == 'C'
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
    a = a_body.scope.self_ptr
    
    a_header.scope.should == Scope::GlobalScope
    a.class_used.path.should == 'Class'
    a.value.path.should == 'C99'
    a.value.superclass.should == ClassRegistry['Object']
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
    a, b = a_body.scope.self_ptr, b_body.scope.self_ptr
    
    a_header.scope.should == Scope::GlobalScope
    a.class_used.path.should == 'Class'
    a.value.path.should == 'C89'
    b.class_used.path.should == 'Class'
    b.value.path.should == 'CPP'
    b.value.superclass.should == a.value
  end
end