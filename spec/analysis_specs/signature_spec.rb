require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Signature do
  describe '#initialize' do
    it 'assigns the basic struct values when successful' do
      result = Signature.new(
          'hello', Protocols::InstanceProtocol.new(ClassRegistry['Array']),
          [ArgumentBinding.new('a1', WoolObject.new, :positional)])
      result.name.should == 'hello'
      result.return_protocol.should == ClassRegistry['Array'].protocol
      result.arguments.size.should == 1
      result.arguments.first.should ==
          ArgumentBinding.new('a1', WoolObject.new, :positional)
    end
    
    it 'requires a string name' do
      expect {
        Signature.new(:hello, Protocols::InstanceProtocol.new(ClassRegistry['Array']),
            [ArgumentBinding.new('a1', WoolObject.new, :positional)])
      }.to raise_error(ArgumentError)
    end
    
    it 'requires a protocol for a return protocol' do
      expect {
        Signature.new('hello', 'Array',
            [ArgumentBinding.new('a1', WoolObject.new, :positional)])
      }.to raise_error(ArgumentError)
    end
    
    it 'requires an array for its argument list' do
      expect {
        Signature.new('hello', Protocols::InstanceProtocol.new(ClassRegistry['Array']),
            ArgumentBinding.new('a1', WoolObject.new, :positional))
      }.to raise_error(ArgumentError)
    end
    
    it 'requires its argument list be an array of Argument objects' do
      expect {
        Signature.new(
            'hello', ClassRegistry['Array'], ['a1'])
      }.to raise_error(ArgumentError)
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
            arg.protocol.should == Protocols::UnknownProtocol.new
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
          [x, a, y, z, d].each {|arg| arg.protocol.should == Protocols::UnknownProtocol.new }
          rest.protocol.should == ProtocolRegistry['Array'].first
          blk.protocol.should == ProtocolRegistry['Proc'].first
          a.default_value_sexp.type.should == :@int
          y.default_value_sexp.type.should == :@int
        end
      end
    end
  end
end