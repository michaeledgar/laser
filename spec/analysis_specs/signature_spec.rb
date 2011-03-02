require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Signature do
  describe '#initialize' do
    it 'assigns the basic struct values when successful' do
      result = Signature.new(
          'hello',
          [Bindings::ArgumentBinding.new('a1', LaserObject.new, :positional)],
          Types::ClassType.new('Array', :covariant))
      result.name.should == 'hello'
      result.return_type.should == Types::ClassType.new('Array', :covariant)
      result.arguments.size.should == 1
      result.arguments.first.should ==
          Bindings::ArgumentBinding.new('a1', LaserObject.new, :positional)
    end
    
    it 'requires a string name' do
      expect {
        Signature.new(:hello,
            [Bindings::ArgumentBinding.new('a1', LaserObject.new, :positional)],
            Types::ClassType.new('Array', :covariant))
      }.to raise_error(ArgumentError)
    end
    
    it 'requires a type for a return type' do
      expect {
        Signature.new('hello',
            [Bindings::ArgumentBinding.new('a1', LaserObject.new, :positional)], 'Array')
      }.to raise_error(ArgumentError)
    end
    
    it 'requires an array for its argument list' do
      expect {
        Signature.new('hello',
            Bindings::ArgumentBinding.new('a1', LaserObject.new, :positional),
            Types::ClassType.new('Array', :covariant))
      }.to raise_error(ArgumentError)
    end
    
    it 'requires its argument list be an array of Argument objects' do
      expect {
        Signature.new('hello', ['a1'], ClassRegistry['Array'])
      }.to raise_error(ArgumentError)
    end
  end
  
  describe '#arity' do
    it 'should compute a finite range without a rest param' do
      sexp = Sexp.new(Ripper.sexp('def a(x, a=2, y=3, z, d, &blk); end'))
      signature = Signature.for_definition_sexp('a', sexp, Sexp.new([]))
      signature.arity.should == (3..5)
    end
    
    it 'should compute an infinite range in the presence of a rest parameter' do
      sexp = Sexp.new(Ripper.sexp('def a(x, a=2, y=3, *rest, z, d, &blk); end'))
      signature = Signature.for_definition_sexp('a', sexp, Sexp.new([]))
      signature.arity.should == (3..Float::INFINITY)
    end
  end
  
  describe '::for_definition_sexp' do
    describe 'when given the definition of an empty method' do
      it 'creates a signature with an empty argument list' do
        sexp = Sexp.new(Ripper.sexp('def a(); end'))
        signature = Signature.for_definition_sexp('a', sexp, Sexp.new([]))
        signature.arguments.should be_empty
      end
    end

    describe 'when given simple positional arguments' do
      it 'creates a signature with corresponding positional arguments' do
        sexp = Sexp.new(Ripper.sexp('def a(x, y, z); end'))
        signature = Signature.for_definition_sexp('a', sexp, Sexp.new([]))
        signature.arguments.tap do |args|
          args.size.should be 3
          args.each do |arg|
            arg.kind.should be :positional
            arg.expr_type.should == Types::TOP
            arg.default_value_sexp.should be nil
          end
          x, y, z = args
          x.name.should == 'x'
          y.name.should == 'y'
          z.name.should == 'z'
        end
      end
    end
    
    describe 'when given a complex definition exercising all argument types' do
      it 'creates the correct, corresponding argument list' do
        sexp = Sexp.new(Ripper.sexp('def a(x, a=2, y=3, *rest, z, d, &blk); end'))
        signature = Signature.for_definition_sexp('a', sexp, Sexp.new([]))
        signature.arguments.tap do |args|
          names = ['x', 'a', 'y', 'rest', 'z', 'd', 'blk']
          kinds = [:positional, :optional, :optional, :rest, :positional, :positional, :block]
          args.zip(names).each {|arg, name| arg.name.should == name }
          args.zip(kinds).each {|arg, kind| arg.kind.should == kind }
          x, a, y, rest, z, d, blk = args
          [x, a, y, z, d].each {|arg| arg.expr_type.should == Types::TOP }
          rest.expr_type.should == Types::ClassType.new('Array', :covariant)
          blk.expr_type.should == Types::ClassType.new('Proc', :covariant)
          a.default_value_sexp.type.should == :@int
          y.default_value_sexp.type.should == :@int
        end
      end
    end
  end
end