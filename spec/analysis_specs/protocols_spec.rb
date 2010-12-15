require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SexpAnalysis::Protocols::ClassProtocol do
  before do
    a = SexpAnalysis::WoolClass.new('A')
    @a_proto = a.protocol
    b = SexpAnalysis::WoolClass.new('B') do |b|
      b.add_method(SexpAnalysis::WoolMethod.new('foo') do |method|
        method.add_signature(@a_proto, [])
        method.add_signature(b.protocol, [@a_proto])
      end)
      b.add_method(SexpAnalysis::WoolMethod.new('bar') do |method|
        method.add_signature(b.protocol, [@a_proto, b.protocol])
      end)
    end
    @b_proto = b.protocol
  end
  
  context '#signatures' do
    it 'returns an empty list when no methods are declared' do
      @a_proto.signatures.should be_empty
    end
    
    it "gets its class's signatures when they are specified, which are its methods' signatures" do
      @b_proto.signatures.should include(SexpAnalysis::Signature.new('foo', @a_proto, []))
      @b_proto.signatures.should include(SexpAnalysis::Signature.new('foo', @b_proto, [@a_proto]))
      @b_proto.signatures.should include(SexpAnalysis::Signature.new('bar', @b_proto, [@a_proto, @b_proto]))
    end
  end
end

describe SexpAnalysis::Protocols::UnionProtocol do
  before do
    @first, @second, @third = mock(:proto1), mock(:proto2), mock(:proto3)
    @union = SexpAnalysis::Protocols::UnionProtocol.new([@first, @second, @third])
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
    