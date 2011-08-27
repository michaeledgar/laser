require_relative 'spec_helper'
require 'set'
describe 'general analyses' do
  extend AnalysisHelpers
  clean_registry
  
  it_should_behave_like 'an annotator'
  
  it 'adds the #scope method to Sexp' do
    Sexp.instance_methods.should include(:scope)
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
    tree = annotate_all('module M13; def silly(*rest); p rest; end; end; class C13; include M13; end')
    # now make sure the method got created in the M13 module!
    method = ClassRegistry['M13'].instance_method(:silly)
    method.should_not be_nil
    rest = method.arguments[0]
    rest.name.should == 'rest'
    rest.kind.should == :rest
    method.name.should == 'silly'
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
    tree = annotate_all('module M49; def self.silly(a, b=a); end; end')
    
    method = ClassRegistry['M49'].singleton_class.instance_method(:silly)
    method.should_not be_nil
    a = method.arguments[0]
    a.name.should == 'a'
    a.kind.should == :positional
    b = method.arguments[1]
    b.name.should == 'b'
    b.kind.should == :optional
    method.name.should == 'silly'
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
    tree = annotate_all('module M50; class << self; def silly(a, b=a); end; end; end')
    
    method = ClassRegistry['M50'].singleton_class.instance_method(:silly)
    method.should_not be_nil
    a = method.arguments[0]
    a.name.should == 'a'
    a.kind.should == :positional
    b = method.arguments[1]
    b.name.should == 'b'
    b.kind.should == :optional
    method.name.should == 'silly'
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
    tree = annotate_all('class C51; end; class << C51; def silly(a, b=a); end; end')
    
    method = ClassRegistry['C51'].singleton_class.instance_method(:silly)
    method.should_not be_nil
    a = method.arguments[0]
    a.name.should == 'a'
    a.kind.should == :positional
    b = method.arguments[1]
    b.name.should == 'b'
    b.kind.should == :optional
    method.name.should == 'silly'
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
    tree = annotate_all('class C89; end; class CPP < C89; end')
    a, b = ClassRegistry['C89'], ClassRegistry['CPP']
    
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
    tree = annotate_all('module WWD; end; class WWD::SuperModule < Module; end')

    mod = ClassRegistry['WWD']
    mod.should be_a(LaserModule)
    supermod = ClassRegistry['WWD::SuperModule']
    supermod.should be_a(LaserClass)
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
    tree = annotate_all('class Alpha; def do_xyz(a, b=a); p b; end; end; class B22 < Alpha; end')
    # now make sure the method got created in the M13 module!
    ['Alpha', 'B22'].each do |klass|
      method = ClassRegistry[klass].instance_method(:do_xyz)
      method.should_not be_nil
      a = method.arguments[0]
      a.name.should == 'a'
      a.kind.should == :positional
      b = method.arguments[1]
      b.name.should == 'b'
      b.kind.should == :optional
      method.name.should == 'do_xyz'
    end
    tree.all_errors.should be_empty
  end

  it 'removes methods via #remove_method' do
    annotate_all('class RM1; def do_xyz(a); end; end')
    ClassRegistry['RM1'].instance_method(:do_xyz).should be_a(LaserMethod)
    annotate_all('class RM1; remove_method :do_xyz; end')
    ClassRegistry['RM1'].instance_method(:do_xyz).should be nil
  end
  
  it 'passes resolution to superclasses after #remove_method' do
    annotate_all('class RM2; def do_xyz(a); end; end; class RMSub < RM2; def do_xyz(b); end; end')
    ClassRegistry['RMSub'].instance_method(:do_xyz).should be_a(LaserMethod)
    ClassRegistry['RMSub'].instance_method(:do_xyz).should_not ==
        ClassRegistry['RM2'].instance_method(:do_xyz)

    annotate_all('class RMSub; remove_method :do_xyz; end')
    ClassRegistry['RMSub'].instance_method(:do_xyz).should ==
        ClassRegistry['RM2'].instance_method(:do_xyz)
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
    tree = annotate_all('def abce(bar, &blk); p blk; end')
    method = Scope::GlobalScope.self_ptr.singleton_class.instance_method(:abce)
    method.should_not be_nil
    Scope::GlobalScope.self_ptr.singleton_class.visibility_table[:abce].should == :private
    bar = method.arguments[0]
    bar.name.should == 'bar'
    bar.kind.should == :positional
    blk = method.arguments[1]
    blk.name.should == 'blk'
    blk.kind.should == :block
    method.name.should == 'abce'
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
    tree = annotate_all('def self.abcd(bar, &blk); p blk; end')
    method = Scope::GlobalScope.self_ptr.singleton_class.instance_method(:abcd)
    method.should_not be_nil
    bar = method.arguments[0]
    bar.name.should == 'bar'
    bar.kind.should == :positional
    blk = method.arguments[1]
    blk.name.should == 'blk'
    blk.kind.should == :block
    method.name.should == 'abcd'
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
  it 'creates new constant bindings as new constants are assigned to' do
    tree = annotate_all('module TestA; PI = 3.14; TAU = PI * 2; end')
    
    ClassRegistry['TestA'].should be_a(LaserModule)
    ClassRegistry['TestA'].const_get('PI').should_not be_nil
    ClassRegistry['TestA'].const_get('TAU').should_not be_nil
  end
  
  it 'handles module inclusions done in the typical method-call fashion' do
    input = 'module A113; end; module B113; end; class C113; include A113, B113; end'
    tree = annotate_all(input)
    
    c113 = ClassRegistry['C113']
    c113.should_not be nil
    c113.ancestors.should == [ClassRegistry['C113'], ClassRegistry['A113'], ClassRegistry['B113'],
                              ClassRegistry['Object'], ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
                              
    tree.all_errors.should be_empty
  end
  
  it 'handles complex module/class hierarchies' do
    input = "module A114; end; module B114; include A114; end; module C114; include B114; end\n" +
            "class X114; include A114; end; class Y114 < X114; include C114; end"
    tree = annotate_all(input)
    
    ClassRegistry['A114'].ancestors.should == [ClassRegistry['A114']]
    ClassRegistry['B114'].ancestors.should == [ClassRegistry['B114'], ClassRegistry['A114']]
    ClassRegistry['C114'].ancestors.should == [ClassRegistry['C114'], ClassRegistry['B114'], ClassRegistry['A114']]
    
    ClassRegistry['X114'].ancestors.should == [ClassRegistry['X114'], ClassRegistry['A114'], ClassRegistry['Object'],
                                               ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
    ClassRegistry['Y114'].ancestors.should == [ClassRegistry['Y114'], ClassRegistry['C114'], ClassRegistry['B114'],
                                               ClassRegistry['X114'], ClassRegistry['A114'], ClassRegistry['Object'],
                                               ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
    tree.all_errors.should be_empty
  end
  
  it 'generates an error when a class is re-opened as a module' do
    input = "class A115; end; module A115; end"
    tree = annotate_all(input)
    
    tree.errors.should_not be_empty
    tree.all_errors.first.should be_a(TopLevelSimulationRaised)
    err = tree.all_errors.first
    err.error.normal_class.should == ClassRegistry['LaserReopenedClassAsModuleError']
  end
  
  it 'generates an error when a module is re-opened as a class' do
    input = "module A116; end; class A116; end"
    tree = annotate_all(input)
    
    tree.errors.should_not be_empty
    tree.all_errors.first.should be_a(TopLevelSimulationRaised)
    err = tree.all_errors.first
    err.error.normal_class.should == ClassRegistry['LaserReopenedModuleAsClassError']
  end
  
  it 'handles module inclusions done in the parenthesized method-call fashion' do
    input = 'module A117; end; module B117; end; class C117; include(A117, B117); end'
    tree = annotate_all(input)
    
    c117 = ClassRegistry['C117']
    c117.should_not be nil
    c117.ancestors.should == [ClassRegistry['C117'], ClassRegistry['A117'],
                              ClassRegistry['B117'], ClassRegistry['Object'],
                              ClassRegistry['Kernel'], ClassRegistry['BasicObject']]

    tree.all_errors.should be_empty
  end
  
  it 'reports an error when a module is included unnecessarily' do
    input = 'module A240; end; class B240; include A240; end; class C240 < B240; include A240; end'
    tree = annotate_all(input)
    
    c240 = ClassRegistry['C240']
    c240.should_not be nil
    c240.ancestors.should == [ClassRegistry['C240'], ClassRegistry['B240'],
                              ClassRegistry['A240'], ClassRegistry['Object'],
                              ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
    tree.all_errors.should_not be_empty
    tree.all_errors.size.should == 1
    tree.all_errors.first.should be_a(TopLevelSimulationRaised)
    err = tree.all_errors.first
    err.error.class.should == DoubleIncludeError
  end
  
  it 'handles module extensions done in the typical method-call fashion' do
    input = 'module A118; end; module B118; end; class C118; extend A118, B118; end'
    tree = annotate_all(input)
    
    c118 = ClassRegistry['C118']
    c118.should_not be nil
    c118.singleton_class.ancestors.should == [ClassRegistry['C118'].singleton_class,
                                              ClassRegistry['A118'], ClassRegistry['B118'],
                                              ClassRegistry['Object'].singleton_class,
                                              ClassRegistry['BasicObject'].singleton_class,
                                              ClassRegistry['Class'], ClassRegistry['Module'],
                                              ClassRegistry['Object'], ClassRegistry['Kernel'],
                                              ClassRegistry['BasicObject']]
    tree.all_errors.should be_empty
  end

  it 'handles complex module/class extension hierarchies' do
    input = "module A119; end; module B119; extend A119; end; module C119; extend B119; end\n" +
            "class X119; extend A119; end; class Y119 < X119; extend C119; end"
    tree = annotate_all(input)
    
    ClassRegistry['A119'].singleton_class.ancestors.should ==
        [ClassRegistry['A119'].singleton_class, ClassRegistry['Module'],
         ClassRegistry['Object'], ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
    ClassRegistry['B119'].singleton_class.ancestors.should ==
        [ClassRegistry['B119'].singleton_class, ClassRegistry['A119'],
         ClassRegistry['Module'], ClassRegistry['Object'], ClassRegistry['Kernel'],
         ClassRegistry['BasicObject']]
    ClassRegistry['C119'].singleton_class.ancestors.should ==
        [ClassRegistry['C119'].singleton_class, ClassRegistry['B119'],
         ClassRegistry['Module'], ClassRegistry['Object'], ClassRegistry['Kernel'],
         ClassRegistry['BasicObject']]

    ClassRegistry['X119'].singleton_class.ancestors.should ==
        [ClassRegistry['X119'].singleton_class, ClassRegistry['A119'],
         ClassRegistry['Object'].singleton_class,
         ClassRegistry['BasicObject'].singleton_class,
         ClassRegistry['Class'], ClassRegistry['Module'],
         ClassRegistry['Object'], ClassRegistry['Kernel'],
         ClassRegistry['BasicObject']]
    ClassRegistry['Y119'].singleton_class.ancestors.should ==
        [ClassRegistry['Y119'].singleton_class, ClassRegistry['C119'],
         ClassRegistry['X119'].singleton_class, ClassRegistry['A119'],
         ClassRegistry['Object'].singleton_class,
         ClassRegistry['BasicObject'].singleton_class,
         ClassRegistry['Class'], ClassRegistry['Module'],
         ClassRegistry['Object'], ClassRegistry['Kernel'],
         ClassRegistry['BasicObject']]
         
    tree.all_errors.should be_empty
  end
  
  it 'handles module extensions done in the parenthesized method-call fashion' do
    input = 'module A120; end; module B120; end; class C120; extend(A120, B120); end'
    tree = annotate_all(input)
    
    c120 = ClassRegistry['C120']
    c120.should_not be nil
    c120.singleton_class.ancestors.should == [ClassRegistry['C120'].singleton_class,
                                              ClassRegistry['A120'], ClassRegistry['B120'],
                                              ClassRegistry['Object'].singleton_class,
                                              ClassRegistry['BasicObject'].singleton_class,
                                              ClassRegistry['Class'], ClassRegistry['Module'],
                                              ClassRegistry['Object'], ClassRegistry['Kernel'],
                                              ClassRegistry['BasicObject']]
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
    tree = annotate_all(input)
    
    errors = tree.all_errors
    errors.should_not be_empty
    errors.first.should be_a(TopLevelSimulationRaised)
    errors.first.error.class.should == ArgumentError
  end
  
  it 'switches to private visibility upon reaching a call to #private in a class/module' do
    input = 'class A122; private; def foobar; end; end'
    tree = annotate_all(input)

    ClassRegistry['A122'].visibility_table[:foobar].should == :private
  end
  
  it 'does not switch to private visibility if a local variable is called private' do
    input = 'class A123; private = 5; private; def foobar; end; end'
    tree = annotate_all(input)

    ClassRegistry['A123'].visibility_table[:foobar].should == :public
  end
  
  it 'switches back and forth from public, private, and protected visibility in a class/module' do
    input = 'module A124; def abc; end; private; def foobar; end; protected; def silly; end; private; def priv; end; end'
    tree = annotate_all(input)

    ClassRegistry['A124'].visibility_table[:abc].should == :public
    ClassRegistry['A124'].visibility_table[:foobar].should == :private
    ClassRegistry['A124'].visibility_table[:silly].should == :protected
    ClassRegistry['A124'].visibility_table[:priv].should == :private
  end
  
  it 'switches to back visibility when re-opening the same class from within (complex edge case)' do
    input = 'class E1; private; class ::E1; def foo; end; end; def bar; end; end'
    tree = annotate_all(input)

    ClassRegistry['E1'].visibility_table[:foo].should == :public
    ClassRegistry['E1'].visibility_table[:bar].should == :private
  end
  
  it 'switches to private on module_function and back on public/protected' do
    input = 'module A200; def abc; end; module_function; def foobar; end; protected;' +
            'def silly; end; public; def priv; end; end'
    tree = annotate_all(input)

    ClassRegistry['A200'].visibility_table[:abc].should == :public
    ClassRegistry['A200'].visibility_table[:foobar].should == :private
    ClassRegistry['A200'].visibility_table[:silly].should == :protected
    ClassRegistry['A200'].visibility_table[:priv].should == :public
  end
  
  it 'sets all module_function methods to private when specified as arguments' do
    input = 'module A201; def abc; end; def foobar; end; def silly; end; module_function :abc, :silly; end'
    tree = annotate_all(input)

    ClassRegistry['A201'].visibility_table[:abc].should == :private
    ClassRegistry['A201'].visibility_table[:foobar].should == :public
    ClassRegistry['A201'].visibility_table[:silly].should == :private
  end

  it 'creates public singleton class methods when module_function is used with no args' do
    input = 'module A202; def def; end; module_function; def foobar; "hi"; 3; end;' +
            'def silly; /regex/; end; public; def priv; end; end'
    tree = annotate_all(input)

    ClassRegistry['A202'].singleton_class.visibility_table[:foobar].should == :public
    ClassRegistry['A202'].singleton_class.visibility_table[:silly].should == :public
    ClassRegistry['A202'].singleton_class.instance_method(:def).should be nil
    ClassRegistry['A202'].singleton_class.instance_method(:priv).should be nil
  end
  
  it 'creates public singleton class methods when module_function is used with args' do
    input = 'module A203; def def; end; def foobar; "hi"; 3; end;' +
            'def silly; /regex/; end; public; def priv; end; module_function :foobar, :silly; end'
    tree = annotate_all(input)

    ClassRegistry['A203'].singleton_class.visibility_table[:foobar].should == :public
    ClassRegistry['A203'].singleton_class.visibility_table[:silly].should == :public
    ClassRegistry['A203'].singleton_class.instance_method(:def).should be nil
    ClassRegistry['A203'].singleton_class.instance_method(:priv).should be nil
  end
  
  it 'uses a default private scope at the top level but can switch to public and private' do
    input = 'def t11; end; public; def t12; end; private; def t13; end'
    tree = annotate_all(input)

    singleton = Scope::GlobalScope.self_ptr.singleton_class
    singleton.visibility_table[:t11].should == :private
    singleton.visibility_table[:t12].should == :public
    singleton.visibility_table[:t13].should == :private
  end
  
  it 'raises an error if you try to use protected at the top level' do
    input = 'def t14; end; protected; def t15; end; public; def t16; end'
    tree = annotate_all(input)
    tree.all_errors.size.should be 1
    tree.all_errors.first.should be_a(TopLevelSimulationRaised)
    tree.all_errors.first.error.normal_class.should == ClassRegistry['NameError']
    
    # recovers by not changing visibility
    # singleton = Scope::GlobalScope.self_ptr.singleton_class
    # singleton.visibility_table[:t14].should == :private
    # singleton.visibility_table[:t15].should == :private
    # singleton.visibility_table[:t16].should == :public
  end
  
  it 'allows specifying private/public/protected for individual methods at the class level' do
    input = 'class A125; def t17; end; def t18; end; def t19; end; private *[:t17, :t19]; end'
    tree = annotate_all(input)

    ClassRegistry['A125'].visibility_table[:t17].should == :private
    ClassRegistry['A125'].visibility_table[:t18].should == :public
    ClassRegistry['A125'].visibility_table[:t19].should == :private
  end
  
  
  it 'allows specifying private/public/protected for individual methods at the top level' do
    input = 'def t17; end; def t18; end; def t19; end; public *[:t17, :t19]'
    tree = annotate_all(input)

    # recovers by not changing visibility
    singleton = Scope::GlobalScope.self_ptr.singleton_class
    singleton.visibility_table[:t17].should == :public
    singleton.visibility_table[:t18].should == :private
    singleton.visibility_table[:t19].should == :public
  end
  
  it 'can resolve constant aliasing with superclasses' do
    tree = annotate_all('class Alpha111; end; Beta111 = Alpha111; class B290 < Beta111; end')
    
    ClassRegistry['B290'].superclass.should == ClassRegistry['Alpha111']
    
    tree.all_errors.should be_empty
  end
  
  describe 'performing requires' do
    before do
      @load_paths = Scope::GlobalScope.lookup('$:').value
      @features = Scope::GlobalScope.lookup('$"').value
      @original = @load_paths.dup
      @orig_features = @features.dup
    end
    
    after do
      @load_paths.replace(@original)
      @features.replace(@orig_features)
    end
    
    it 'should load the file from $: if it is not yet in $"' do
      @load_paths.unshift('/abc/def')
      File.should_receive(:exist?).with('/abc/def/foobaz.rb').and_return(true)
      File.should_receive(:read).with('/abc/def/foobaz.rb').and_return('class Alpha112 < Hash;end')
      annotate_all("require 'foobaz'")
      ClassRegistry['Alpha112'].superclass.should == ClassRegistry['Hash']
    end
    
    it 'should check all paths in $: for the file in a row' do     
      @load_paths.unshift('/abc/def').unshift('/def/jkl').unshift('/jkl/uio')
      File.should_receive(:exist?).with('/jkl/uio/foobaz.rb').and_return(false)
      File.should_receive(:exist?).with('/def/jkl/foobaz.rb').and_return(false)
      File.should_receive(:exist?).with('/abc/def/foobaz.rb').and_return(true)
      File.should_receive(:read).with('/abc/def/foobaz.rb').and_return('class Alpha113 < Array;end')
      annotate_all("require 'foobaz'")
      ClassRegistry['Alpha113'].superclass.should == ClassRegistry['Array']
    end
    
    it 'should not load the file if it is found in $"' do
      @load_paths.unshift('/abc/def').unshift('/def/jkl').unshift('/jkl/uio')
      @features.unshift('/abc/def/foobaz.rb')
      File.should_receive(:exist?).with('/jkl/uio/foobaz.rb').and_return(false)
      File.should_receive(:exist?).with('/def/jkl/foobaz.rb').and_return(false)
      File.should_receive(:exist?).with('/abc/def/foobaz.rb').and_return(true)
      File.should_not_receive(:read)
      annotate_all("require 'foobaz'")
    end
  end

  it 'should raise a SuperclassMismatchError when an improper superclass is specified' do
    input = 'class A250 < String; end; class A250 < Fixnum; end'
    tree = annotate_all(input)
    tree.all_errors.size.should be 1
    tree.all_errors.first.should be_a(TopLevelSimulationRaised)
    tree.all_errors.first.error.normal_class.should == ClassRegistry['LaserSuperclassMismatchError']
  end
  
  it "should not raise a SuperclassMismatchError when BasicObject's superclass is omitted" do
    input = 'class BasicObject; end'
    tree = annotate_all(input)
    tree.all_errors.should be_empty
  end
  
  it "should not raise a SuperclassMismatchError when BasicObject's superclass is nil" do
    input = 'class BasicObject < nil; end'
    tree = annotate_all(input)
    tree.all_errors.should be_empty
  end
  
  it "should raise a SuperclassMismatchError when BasicObject's superclass is specified and not nil" do
    input = 'class BasicObject < String; end'
    tree = annotate_all(input)
    tree.all_errors.size.should be 1
    tree.all_errors.first.should be_a(TopLevelSimulationRaised)
    tree.all_errors.first.error.normal_class.should == ClassRegistry['LaserSuperclassMismatchError']
  end
  
  it "should not raise a SuperclassMismatchError when Object's superclass is omitted" do
    input = 'class Object; end'
    tree = annotate_all(input)
    tree.all_errors.should be_empty
  end
  
  it "should not raise a SuperclassMismatchError when Object's superclass is BasicObject" do
    input = 'class Object < BasicObject; end'
    tree = annotate_all(input)
    tree.all_errors.should be_empty
  end
  
  it "should raise a SuperclassMismatchError when Object's superclass is specified and not BasicObject" do
    input = 'class Object < Array; end'
    tree = annotate_all(input)
    tree.all_errors.size.should be 1
    tree.all_errors.first.should be_a(TopLevelSimulationRaised)
    tree.all_errors.first.error.normal_class.should == ClassRegistry['LaserSuperclassMismatchError']
  end
  
  it "should not raise a SuperclassMismatchError when Class's superclass is omitted" do
    input = 'class Class; end'
    tree = annotate_all(input)
    tree.all_errors.should be_empty
  end
  
  it "should not raise a SuperclassMismatchError when Class's superclass is Module" do
    input = 'class Class < Module; end'
    tree = annotate_all(input)
    tree.all_errors.should be_empty
  end
  
  it "should raise a SuperclassMismatchError when Class's superclass is specified and not Module" do
    input = 'class Class < BasicObject; end'
    tree = annotate_all(input)
    tree.all_errors.size.should be 1
    tree.all_errors.first.should be_a(TopLevelSimulationRaised)
    tree.all_errors.first.error.normal_class.should == ClassRegistry['LaserSuperclassMismatchError']
  end
  
  it "should not raise a SuperclassMismatchError when a class is opened without it's Object superclass" do
    input = 'class String; end'
    tree = annotate_all(input)
    tree.all_errors.should be_empty
  end
  
  it 'observes aliases and sets the corresponding instance methods correctly' do
    input = 'class SA99; def foo; end; alias silly foo; end'
    annotate_all(input)
    ClassRegistry['SA99'].instance_method(:silly).should be(
        ClassRegistry['SA99'].instance_method(:foo))
  end
  
  it 'observes undefs and sets the corresponding instance method to nil' do
    input = 'class SA100; def foo; end; end; class SA101 < SA100; undef foo, :inspect; end'
    annotate_all(input)
    ClassRegistry['SA100'].instance_method(:foo).should_not be nil
    ClassRegistry['SA100'].instance_method(:inspect).should_not be nil
    ClassRegistry['SA101'].instance_method(:foo).should be nil
    ClassRegistry['SA101'].instance_method(:inspect).should be nil
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
    tree = annotate_all(<<-EOF
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
)
    modules = %w(And And::Or And::Or::Is And::Or::Is::Ten And::Or::Is::Ten::Seven
                 And::Or::Is::Ten::Kind::Silly)
    modules.each { |mod| ClassRegistry[mod].should be_a(LaserModule) }
    ClassRegistry['And::Or::Type'].should be_a(LaserClass)
    ClassRegistry['And::Or::Type'].superclass.should be ClassRegistry['Object']
    ClassRegistry['And::Or::Is::Ten::Kind'].should be_a(LaserClass)
    ClassRegistry['And::Or::Is::Ten::Kind'].superclass.should be ClassRegistry['And::Or::Type']
  end
  
  describe 'with a real ruby file as input' do
    before do
      @input = %q{
module Laser
  module Analysis
    module Bindings
      # This class represents a Base in Ruby. It may have a known protocol (type),
      # class, value (if constant!), and a variety of other details.
      class Base
        include Comparable

        def initialize(name, value)
          @name = name
          @value = :uninitialized
          bind!(value)
        end
        
        def name
          @name
        end
        
        def name=(other)
          @name = other
        end
        
        def value
          @value
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
        # 
        # def to_s
        #   inspect
        # end
        # 
        # def inspect
        #   "#<#{self.class.name.split('::').last}: #{name}>"
        # end
      end

      class KeywordBinding < Base
        private :bind!
      end

      # Constants have slightly different properties in their bindings: They shouldn't
      # be rebound. However.... Ruby allows it. It prints a warning when the rebinding
      # happens, but we should be able to detect this statically. Oh, and they can't be
      # bound inside a method. That too is easily detected statically.
      class ConstantBinding < Base
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
      # Base for it.
      class LocalVariableBinding < Base
      end

      # Possible extension ideas:
      # - Initial definition point?
      class GlobalVariableBinding < Base
      end

      class ArgumentBinding < Base
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
    
    pending 'correctly resolves many bindings, creates new modules and classes, and defines methods' do
      tree = annotate_all(@input)      
      
      bindings_mod = 'Laser::Analysis::Bindings'
      ClassRegistry['Laser'].should be_a(LaserModule)
      ClassRegistry['Laser::Analysis'].should be_a(LaserModule)
      ClassRegistry[bindings_mod].should be_a(LaserModule)
      ClassRegistry["#{bindings_mod}::Base"].should be_a(LaserClass)
      ClassRegistry["#{bindings_mod}::KeywordBinding"].should be_a(LaserClass)
      ClassRegistry["#{bindings_mod}::ConstantBinding"].should be_a(LaserClass)
      ClassRegistry["#{bindings_mod}::LocalVariableBinding"].should be_a(LaserClass)
      ClassRegistry["#{bindings_mod}::GlobalVariableBinding"].should be_a(LaserClass)
      ClassRegistry["#{bindings_mod}::ArgumentBinding"].should be_a(LaserClass)
      
      ClassRegistry["#{bindings_mod}::Base"].superclass.should be ClassRegistry['Object']
      [ClassRegistry["#{bindings_mod}::KeywordBinding"],
       ClassRegistry["#{bindings_mod}::ConstantBinding"],
       ClassRegistry["#{bindings_mod}::LocalVariableBinding"],
       ClassRegistry["#{bindings_mod}::GlobalVariableBinding"],
       ClassRegistry["#{bindings_mod}::ArgumentBinding"]].each do |subclass|
        subclass.superclass.should be ClassRegistry["#{bindings_mod}::Base"]
      end
      
      generic = ClassRegistry["#{bindings_mod}::Base"]
      class_binding = ClassRegistry["#{bindings_mod}::ConstantBinding"]
      kw_binding = ClassRegistry["#{bindings_mod}::KeywordBinding"]
      arg_binding = ClassRegistry["#{bindings_mod}::ArgumentBinding"]

      arg_binding.ancestors.should == [arg_binding, generic, ClassRegistry['Comparable'],
                                       ClassRegistry['Object'], ClassRegistry['Kernel'],
                                       ClassRegistry['BasicObject']]
      
      %w(initialize bind! <=> scope protocol class_used to_s inspect).each do |method|
        generic.instance_method(method).should_not be_nil
        generic.visibility_table[method].should == :public
      end
      kw_binding.visibility_table[:bind!].should == :private
      init_method = generic.instance_method(:initialize)
      init_method.arguments.size.should == 2
      init_method.arguments.map(&:name).should == ['name', 'value']
      
      arg_binding_method = arg_binding.instance_method(:initialize)
      arg_binding_method.arguments.size.should == 4
      arg_binding_method.arguments.map(&:name).should == ['name', 'value', 'kind', 'default_value']
      
      
      generic.instance_method(:initialize).arity.should == (2..2)
      generic.instance_method(:bind!).arity.should == (1..1)
      generic.instance_method(:<=>).arity.should == (1..1)
      generic.instance_method(:scope).arity.should == (0..0)
      generic.instance_method(:class_used).arity.should == (0..0)
      class_binding.instance_method(:bind!).arity.should == (1..2)
      arg_binding.instance_method(:initialize).arity.should == (3..4)
    end
  end
end
