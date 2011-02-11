require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe LiteralTypeAnnotation do
  extend AnalysisHelpers
  clean_registry
  
  it_should_behave_like 'an annotator'
  
  it 'adds the #method_estimate method to Sexp' do
    Sexp.instance_methods.should include(:method_estimate)
  end
  
  describe 'using explicit super' do
    it 'should give an error if used outside of a method' do
      tree = annotate_all('class A991; super(); end')
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should be 1
      tree.all_errors[0].should be_a(NotInMethodError)
    end
    
    it "should bind to the first superclass implementation of the method" do
      input = "class A992; def silly992(x); end; end; class B992 < A992; end\n" +
              'class C992 < B992; def silly992(x); super(x); end; end'
      tree = annotate_all(input)
      sexp = tree.deep_find { |node| node.type == :super }
      expected_method = ClassRegistry['A992'].instance_methods['silly992']
      sexp.method_estimate.should == Set.new([expected_method])
    end
    
    it 'gives an error if no superclass implements the given method' do
      input = "class A994; end; class B994 < A994; end\n" +
              'class C994 < B994; def silly994(x); super(x); end; end'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should be 1
      tree.all_errors[0].should be_a(NoSuchMethodError)
    end
    
    it 'gives an error if the superclass implementation has incompatible arity' do
      input = "class A987; def silly987(x, y); end; end; class B987 < A987; end\n" +
              'class C987 < B987; def silly987(x); super x; end; end'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should be 1
      tree.all_errors[0].should be_a(IncompatibleArityError)
    end

    it 'does not give an error if the superclass implementation has compatible ' +
       'arity (more complicated example)' do
      input = "class A988; def silly988(x, y=x); end; end; class B988 < A988; end\n" +
              'class C988 < B988; def silly988(x); super x; end; end'
      tree = annotate_all(input)
      tree.all_errors.should be_empty
    end
    
    it 'gives an error if the superclass implementation has incompatible ' +
       'arity (more complicated example)' do
      input = "class A989; def silly989(x, z, y=x, *rest); end; end; class B989 < A989; end\n" +
              'class C989 < B989; def silly989(x); super(x); end; end'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should be 1
      tree.all_errors[0].should be_a(IncompatibleArityError)
    end

    it 'does not give an error if the superclass implementation has compatible ' +
       'arity (even more complicated example)' do
      input = "class A982; def silly982(a, *rest); end; end; class B982 < A982; end\n" +
              'class C982 < B982; def silly982(x, y, z); super(x, y, z); end; end'
      tree = annotate_all(input)
      tree.all_errors.should be_empty
    end
  end
  
  describe 'using implicit super' do
    it 'should give an error if used outside of a method' do
      tree = annotate_all('class A994; super; end')
      tree.all_errors.should_not be_empty
      tree.all_errors[0].should be_a(NotInMethodError)
    end
    
    it "should bind to the first superclass implementation of the method" do
      input = "class A993; def silly(x); end; end; class B993 < A993; end\n" +
              'class C993 < B993; def silly(x); super; end; end'
      tree = annotate_all(input)
      sexp = tree.deep_find { |node| node.type == :zsuper }
      expected_method = ClassRegistry['A993'].instance_methods['silly']
      sexp.method_estimate.should == Set.new([expected_method])
    end
    
    it 'gives an error if no superclass implements the given method' do
      input = "class A995; end; class B995 < A995; end\n" +
              'class C995 < B995; def silly995(x); super; end; end'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should be 1
      tree.all_errors[0].should be_a(NoSuchMethodError)
    end
    
    it 'gives an error if the superclass implementation has incompatible arity' do
      input = "class A997; def silly997(x, y); end; end; class B997 < A997; end\n" +
              'class C997 < B997; def silly997(x); super; end; end'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should be 1
      tree.all_errors[0].should be_a(IncompatibleArityError)
    end

    it 'does not give an error if the superclass implementation has compatible ' +
       'arity (more complicated example)' do
      input = "class A998; def silly998(x, y=x); end; end; class B998 < A998; end\n" +
              'class C998 < B998; def silly998(x); super; end; end'
      tree = annotate_all(input)
      tree.all_errors.should be_empty
    end
    
    it 'gives an error if the superclass implementation has incompatible ' +
       'arity (more complicated example)' do
      input = "class A999; def silly999(x, z, y=x, *rest); end; end; class B999 < A999; end\n" +
              'class C999 < B999; def silly999(x); super; end; end'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should be 1
      tree.all_errors[0].should be_a(IncompatibleArityError)
    end

    it 'does not give an error if the superclass implementation has compatible ' +
       'arity (even more complicated example)' do
      input = "class A978; def silly978(a, *rest); end; end; class B978 < A978; end\n" +
              'class C978 < B978; def silly978(x, y, z); super; end; end'
      tree = annotate_all(input)
      tree.all_errors.should be_empty
    end
  end
  
  describe 'performing a simple no-arg implicit self call' do
    it 'should resolve to the only method when there are no subclasses' do
      input = 'class A700; def printall(x); foobar; end; def foobar(); end; end'
      
      
      class A700
        def printall(x)
          foobar
        end
        def foobar()
        end
      end
      
      
      tree = annotate_all(input)
      tree.all_errors.should be_empty
      
      foobar_call = tree.deep_find { |node| node.type == :var_ref && node.expanded_identifier == 'foobar' }
      foobar_call.should_not be_nil
      foobar_call.method_estimate.should == [ClassRegistry['A700'].instance_methods['foobar']]
    end
    
    it 'should raise an error when there is no method to resolve to' do
      input = 'class A701; def printall(x); foobar; end; def foobaz(); end; end'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should == 1
      tree.all_errors.first.should be_a(NoSuchMethodError)
    end
    
    it 'should resolve to all possible subclass implementations' do
      input = 'class A702; def printall(x); foobar; end; def foobar(); end; end;' +
              'class A703 < A702; def foobar; end; end; class A704 < A702; def foobar; end; end;' +
              'class A705 < A703; def foobar; end; end'
      tree = annotate_all(input)
      tree.all_errors.should be_empty
      
      foobar_call = tree.deep_find { |node| node.type == :var_ref && node.binding.nil? && node.expanded_identifier == 'foobar' }
      foobar_call.should_not be_nil
      foobar_call.method_estimate.should ==
          [ClassRegistry['A702'].instance_methods['foobar'],
           ClassRegistry['A703'].instance_methods['foobar'],
           ClassRegistry['A705'].instance_methods['foobar'],
           ClassRegistry['A704'].instance_methods['foobar']]
    end
    
    it 'should throw an error if an implementation is found, but has mismatched arity' do
      input = 'class A706 def printall(x); foobar; end; def foobar(x, y=x); end; end'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should == 1
      tree.all_errors.first.should be_a(NoSuchMethodError)
    end
  end
  
  describe 'performing a no-arg method call with a receiver (:call)' do
    it 'should resolve to the appropriate method(s) based on the receiver type' do
      input = '[1, 2].uniq!'
      tree = annotate_all(input)
      tree.all_errors.should be_empty
      
      uniq_call = tree.deep_find { |node| node.type == :call }
      uniq_call.should_not be_nil
      uniq_call.method_estimate.should ==
          [ClassRegistry['Array'].instance_methods['uniq!']]
    end
    
    it 'should resolve to the appropriate method(s) based on the receiver type' do
      input = '"hello world".center(100, "=")'
      tree = annotate_all(input)
      tree.all_errors.should be_empty
      
      center_call = tree.deep_find { |node| node.type == :call }
      center_call.should_not be_nil
      center_call.method_estimate.should ==
          [ClassRegistry['String'].instance_methods['center']]
    end
    
    it 'should raise an error if the method cannot be found on the given type' do
      input = '[1, 2].center(2,3)'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should == 1
      tree.all_errors.first.should be_a(NoSuchMethodError)
    end
    
    it 'should raise an error if the method cannot be found on any type' do
      input = 'x.hiybbprqag(2,3)'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should == 1
      tree.all_errors.first.should be_a(NoSuchMethodError)
    end
  end
  
  describe 'handling binary operators' do
    it 'should resolve to a precise lookup when possible' do
      input = '"hello %s" % ["world!"]'
      tree = annotate_all(input)
      tree.all_errors.should be_empty
      
      mod_call = tree.deep_find { |node| node.type == :binary }
      mod_call.should_not be_nil
      mod_call.method_estimate.should ==
          [ClassRegistry['String'].instance_methods['%']]
    end

    it 'should resolve to all subclass operators by looking up the method with the name of the operator' do
      input = '1 + 3'
      tree = annotate_all(input)
      tree.all_errors.should be_empty
      
      plus_call = tree.deep_find { |node| node.type == :binary }
      plus_call.should_not be_nil
      plus_call.method_estimate.should ==
          [ClassRegistry['Fixnum'].instance_methods['+'],
           ClassRegistry['Bignum'].instance_methods['+']]
    end
    
    it 'should throw an error if the operator does not exist on the given type' do
      input = '"hello" - "el"'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should == 1
      tree.all_errors.first.should be_a(NoSuchMethodError)
    end

    it 'works for custom classes' do
      input = "class A709; def +(other); end; def temp; self + 5; end; end"
      tree = annotate_all(input)
      
      tree.all_errors.should be_empty
      plus_call = tree.deep_find { |node| node.type == :binary }
      plus_call.should_not be_nil
      plus_call.method_estimate.should ==
          [ClassRegistry['A709'].instance_methods['+']]
    end
    
    it 'raises an error if, for some silly reason, the unary operator is defined but with args' do
      input = "class A710; def +(); end; def temp; self + 5; end; end"
      tree = annotate_all(input)
      
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should == 1
      tree.all_errors.first.should be_a(NoSuchMethodError)
      tree.all_errors.first.ast_node.type.should == :binary
    end
  end
  
  describe 'handling unary operators' do
    it 'should resolve to all subclass operators by looking up the method with the name of the operator' do
      input = '-3'
      tree = annotate_all(input)
      tree.all_errors.should be_empty
      
      minus_call = tree.deep_find { |node| node.type == :unary }
      minus_call.should_not be_nil
      minus_call.method_estimate.should ==
          [ClassRegistry['Numeric'].instance_methods['-@'],
           ClassRegistry['Fixnum'].instance_methods['-@'],
           ClassRegistry['Bignum'].instance_methods['-@']]
    end
    
    it 'raises an error when the the operator does not exist on the given type' do
      input = '-"hello"'
      tree = annotate_all(input)
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should == 1
      tree.all_errors.first.should be_a(NoSuchMethodError)
    end

    it 'works for custom classes' do
      input = "class A708; def +@; end; def temp; +self; end; end"
      tree = annotate_all(input)
      
      tree.all_errors.should be_empty
      plus_call = tree.deep_find { |node| node.type == :unary }
      plus_call.should_not be_nil
      plus_call.method_estimate.should ==
          [ClassRegistry['A708'].instance_methods['+@']]
    end
    
    it 'raises an error if, for some silly reason, the unary operator is defined but with args' do
      input = "class A707; def +@(arg1, arg2); end; def temp; +self; end; end"
      tree = annotate_all(input)
      
      tree.all_errors.should_not be_empty
      tree.all_errors.size.should == 1
      tree.all_errors.first.should be_a(NoSuchMethodError)
      tree.all_errors.first.ast_node.type.should == :unary
    end
  end
end