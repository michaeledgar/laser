require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'pp'

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