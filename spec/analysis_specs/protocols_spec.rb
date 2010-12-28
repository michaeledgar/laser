require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Protocols::Base do
  context '#signatures' do
    it 'raises a NotImplementedError' do
      lambda { Protocols::Base.new.signatures }.should raise_error(NotImplementedError)
    end
  end
  
  context '#signatures' do
    it 'raises a NotImplementedError' do
      lambda { Protocols::Base.new <=> Protocols::Base.new }.should raise_error(NotImplementedError)
    end
  end
end

describe Protocols::StructuralProtocol do
  before do
    a = WoolClass.new('A')
    @a_proto = ProtocolRegistry['A'].first
    @sig1 = Signature.new('foo', @a_proto, {})
    @sig2 = Signature.new('foo', @a_proto, {})
  end
end

describe Protocols::InstanceProtocol do
  extend AnalysisHelpers
  clean_registry

  before do
    a = WoolClass.new('A')
    @a_proto = ProtocolRegistry['A'].first
    b = WoolClass.new('B') do |b|
      b.add_instance_method(WoolMethod.new('foo') do |method|
        method.add_signature(Signature.new('foo', @a_proto, {}))
        method.add_signature(Signature.new('foo', ProtocolRegistry['B'].first,
            {'a' => Argument.new('a', :positional, @a_proto)}))
      end)
      b.add_instance_method(WoolMethod.new('bar') do |method|
        method.add_signature(Signature.new('bar', ProtocolRegistry['B'].first,
            {'a' => Argument.new('a', :positional, @a_proto),
             'b' => Argument.new('b', :positional, ProtocolRegistry['B'].first)}))
      end)
    end
    @b_proto = ProtocolRegistry['B'].first
  end
  
  context '#signatures' do
    it 'returns an empty list when no methods are declared' do
      @a_proto.signatures.should be_empty
    end
    
    it "gets its class's signatures when they are specified, which are its methods' signatures" do
      @b_proto.signatures.should include(Signature.new('foo', @a_proto, {}))
      @b_proto.signatures.should include(Signature.new('foo', @b_proto,
          {'a' => Argument.new('a', :positional, @a_proto)}))
      @b_proto.signatures.should include(Signature.new('bar', @b_proto,
          {'a' => Argument.new('a', :positional, @a_proto),
           'b' => Argument.new('b', :positional, @b_proto)}))
    end
  end
end

describe Protocols::UnionProtocol do
  before do
    @first, @second, @third = mock(:proto1), mock(:proto2), mock(:proto3)
    @union = Protocols::UnionProtocol.new([@first, @second, @third])
  end
  
  context '#signatures' do
    it "returns the union of all the protocols' signatures" do
      sigs = mock(:sig1), mock(:sig2), mock(:sig3), mock(:sig4), mock(:sig5), mock(:sig6)
      [@first, @second, @third].each_with_index do |proto, idx|
        proto.should_receive(:signatures).and_return(sigs[idx * 2, 3])
      end
      final_sigs = @union.signatures
      sigs.each {|sig| final_sigs.should include(sig)}
    end
  end
end
    