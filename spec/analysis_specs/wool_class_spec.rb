require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'pp'

describe SexpAnalysis::WoolClass do
  before do
    @a = SexpAnalysis::WoolClass.new('A')
    @b = SexpAnalysis::WoolClass.new('B') do |b|
      b.add_method(SexpAnalysis::WoolMethod.new('foo') do |method|
        method.add_signature(@a, [])
        method.add_signature(b, [@a])
      end)
      b.add_method(SexpAnalysis::WoolMethod.new('bar') do |method|
        method.add_signature(b, [@a, b])
      end)
    end
  end
  
  context '#signatures' do
    it 'returns an empty list when no methods are declared' do
      @a.signatures.should be_empty
    end
    
    it "flattens all its method's signatures" do
      @b.signatures.should include(SexpAnalysis::Signature.new('foo', @a, []))
      @b.signatures.should include(SexpAnalysis::Signature.new('foo', @b, [@a]))
      @b.signatures.should include(SexpAnalysis::Signature.new('bar', @b, [@a, @b]))
    end
  end
end

describe SexpAnalysis::WoolMethod do
  before do
    @a = SexpAnalysis::WoolClass.new('A')
    @b = SexpAnalysis::WoolClass.new('B')
    @method = SexpAnalysis::WoolMethod.new('foobar')
  end
  
  context '#add_signature' do
    it 'creates signature objects and returns them in #signatures' do
      @method.add_signature(@a, [])
      @method.add_signature(@b, [@a, @a])
      @method.signatures.should include(SexpAnalysis::Signature.new('foobar', @a, []))
      @method.signatures.should include(SexpAnalysis::Signature.new('foobar', @b, [@a, @a]))
    end
  end
  
  context '#name' do
    it 'returns the name' do
      @method.name.should == 'foobar'
    end
  end
end