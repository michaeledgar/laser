# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Protocols::Base do
  describe '#signatures' do
    it 'raises a NotImplementedError' do
      expect { Protocols::Base.new.signatures }.to raise_error(NotImplementedError)
    end
  end
  
  describe '#signatures' do
    it 'raises a NotImplementedError' do
      expect { Protocols::Base.new <=> Protocols::Base.new }.to raise_error(NotImplementedError)
    end
  end
  
  describe '#|' do
    it 'creates a protocol that contains both operand protocols' do
      sigs = many_mocks(5)
      protocol1, protocol2 = Protocols::Base.new, Protocols::Base.new
      protocol1.should_receive(:signatures).exactly(5).times.and_return(sigs[0..2])
      protocol2.should_receive(:signatures).exactly(5).times.and_return(sigs[3..4])
      unioned = protocol1 | protocol2
      sigs.each { |sig| unioned.signatures.should include(sig) }
    end
  end
end

describe Protocols::StructuralProtocol do
  extend AnalysisHelpers
  clean_registry
  
  before do
    @foo = Signature.new('foo', ClassRegistry['Class'].protocol, [])
    @bizzle = Signature.new('bizzle', ClassRegistry['Array'].protocol, [])
    @structural = Protocols::StructuralProtocol.new([@foo, @bizzle])
  end
  
  describe '#signatures' do
    it 'returns the current list of signatures, which is initialized during construction' do
      Set.new(@structural.signatures).should == Set.new([@bizzle, @foo])
    end
  end
  
  describe '#inspect' do
    it 'contains the name of the class' do
      @structural.inspect.should include('StructuralProtocol')
    end
  end
end

describe Protocols::InstanceProtocol do
  extend AnalysisHelpers
  clean_registry

  before do
    @a = WoolClass.new('A')
    @a_proto = ProtocolRegistry['A'].first
    @b = WoolClass.new('B') do |b|
      b.add_instance_method!(WoolMethod.new('foo') do |method|
        method.add_signature!(Signature.new('foo', @a_proto, []))
        method.add_signature!(Signature.new('foo', ProtocolRegistry['B'].first,
            [Bindings::ArgumentBinding.new('a', @a, :positional)]))
      end)
      b.add_instance_method!(WoolMethod.new('bar') do |method|
        method.add_signature!(Signature.new('bar', ProtocolRegistry['B'].first,
            [Bindings::ArgumentBinding.new('a', @a, :positional),
             Bindings::ArgumentBinding.new('b', b, :positional)]))
      end)
    end
    @b_proto = ProtocolRegistry['B'].first
  end
  
  describe '#signatures' do
    it 'returns an empty list when no methods are declared' do
      @a_proto.signatures.should be_empty
    end
    
    it "gets its class's signatures when they are specified, which are its methods' signatures" do
      @b_proto.signatures.should include(Signature.new('foo', @a_proto, []))
      @b_proto.signatures.should include(Signature.new('foo', @b_proto,
          [Bindings::ArgumentBinding.new('a', @a, :positional)]))
      @b_proto.signatures.should include(Signature.new('bar', @b_proto,
          [Bindings::ArgumentBinding.new('a', @a, :positional),
           Bindings::ArgumentBinding.new('b', @b, :positional)]))
    end
  end
  
  describe '#to_s' do
    it 'returns the name of the class this protocol represents an instance of' do
      @a_proto.to_s.should == 'A'
      @b_proto.to_s.should == 'B'
    end
  end
end

describe Protocols::UnionProtocol do
  before do
    @first, @second, @third = many_mocks 3
    @union = Protocols::UnionProtocol.new([@first, @second, @third])
  end
  
  describe '#signatures' do
    it "returns the union of all the protocols' signatures" do
      sigs = mock(:sig1), mock(:sig2), mock(:sig3), mock(:sig4), mock(:sig5), mock(:sig6)
      [@first, @second, @third].each_with_index do |proto, idx|
        proto.should_receive(:signatures).and_return(sigs[idx * 2, 3])
      end
      final_sigs = @union.signatures
      sigs.each {|sig| final_sigs.should include(sig)}
    end
  end
  
  describe '#to_s' do
    it 'returns the union members joined by |, as in the annotation language' do
      @first.should_receive(:to_s).and_return('AbcDef')
      @second.should_receive(:to_s).and_return('Hello::World')
      @third.should_receive(:to_s).and_return('#read -> String')
      @union.to_s.should == 'AbcDef | Hello::World | #read -> String'
    end
  end
end


describe Protocols::IntersectionProtocol do
  before do
    @mocks = many_mocks(3)
    @intersection = Protocols::IntersectionProtocol.new(@mocks)
  end
  
  describe '#signatures' do
    it "returns the union of all the protocols' signatures" do
      sigs = many_mocks 10
      @mocks[0].should_receive(:signatures).and_return([sigs[0], sigs[2], sigs[3], sigs[4], sigs[7]])
      @mocks[1].should_receive(:signatures).and_return([sigs[1], sigs[2], sigs[3], sigs[5], sigs[7]])
      @mocks[2].should_receive(:signatures).and_return([sigs[7], sigs[9], sigs[3], sigs[8], sigs[4]])
      final_sigs = @intersection.signatures
      final_sigs.should include(sigs[3])
      final_sigs.should include(sigs[7])
    end
  end
  
  describe '#to_s' do
    it 'returns the union members joined by |, as in the annotation language' do
      intersection = Protocols::IntersectionProtocol.new(@mocks)
      @mocks[0].should_receive(:to_s).and_return('AbcDef')
      @mocks[1].should_receive(:to_s).and_return('Hello::World')
      @mocks[2].should_receive(:to_s).and_return('#read -> String')
      intersection.to_s.should == 'AbcDef ∩ Hello::World ∩ #read -> String'
    end
  end
end
    