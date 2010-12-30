require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

shared_examples_for 'a Ruby module' do
  extend AnalysisHelpers
  clean_registry

  before do
    @a = described_class.new('A')
    @b = described_class.new('B') do |b|
      b.add_instance_method(WoolMethod.new('foo') do |method|
        method.add_signature(Signature.new('foo', @a.protocol, []))
        method.add_signature(Signature.new('foo', b.protocol,
            [Argument.new('a', :positional, @a.protocol)]))
      end)
      b.add_instance_method(WoolMethod.new('bar') do |method|
        method.add_signature(Signature.new('bar', b.protocol,
            [Argument.new('a', :positional, @a.protocol),
             Argument.new('b', :positional, b.protocol)]))
      end)
    end
  end
  
  context '#name' do
    it 'extracts the name from the full path' do
      x = described_class.new('::A::B::C::D::EverybodysFavoriteClass')
      x.name.should == 'EverybodysFavoriteClass'
    end
  end
  
  context '#instance_signatures' do
    it 'returns an empty list when no methods are declared' do
      @a.instance_signatures.should be_empty
    end
    
    it "flattens all its normal instance method's signatures" do
      @b.instance_signatures.should include(Signature.new('foo', @a.protocol, []))
      @b.instance_signatures.should include(Signature.new('foo', @b.protocol,
          [Argument.new('a', :positional, @a.protocol)]))
      @b.instance_signatures.should include(
          Signature.new('bar', @b.protocol,
          [Argument.new('a', :positional, @a.protocol),
           Argument.new('b', :positional, @b.protocol)]))
    end
  end
  
  context '#trivial?' do
    it 'returns true if the module has no methods' do
      @a.trivial?.should be true
    end
    
    it 'returns false if the module has an instance method' do
      @b.trivial?.should be false
    end
  end
  
  context '#nontrivial?' do
    it 'returns false if the module has no methods' do
      @a.nontrivial?.should be false
    end
    
    it 'returns true if the module has an instance method' do
      @b.nontrivial?.should be true
    end
  end
end

describe WoolModule do
  it_should_behave_like 'a Ruby module'
end

describe WoolClass do
  it_should_behave_like 'a Ruby module'
  
  before do
    @a = described_class.new('A')
    @b = described_class.new('B') do |b|
      b.superclass = @a
    end
  end
  
  context '#superclass' do
    it 'returns the superclass specified on the WoolClass' do
      @b.superclass.should == @a
    end
  end
  
  context '#subclasses' do
    it 'returns the set of direct subclasses of the WoolClass' do
      @a.subclasses.should include(@b)
    end
  end
  
  context '#remove_subclass' do
    it 'allows the removal of direct subclasses (just in case we need to)' do
      @a.remove_subclass!(@b)
      @a.subclasses.should_not include(@b)
    end
  end
end

describe 'hierarchy methods' do
  extend AnalysisHelpers
  clean_registry

  before do
    @y = WoolClass.new('Y')
    @y.superclass = @x = WoolClass.new('X')
    @x.superclass = ClassRegistry['Object']
    @y2 = WoolClass.new('Y2')
    @y2.superclass = @x
    @z = WoolClass.new('Z')
    @z.superclass = @y
    @w = WoolClass.new('W')
    @w.superclass = @y2
  end
  
  context '#superclass' do
    it 'should return the direct superclass' do
      @x.superclass.should == ClassRegistry['Object']
      @y.superclass.should == @x
      @y2.superclass.should == @x
      @z.superclass.should == @y
      @w.superclass.should == @y2
    end
  end
  
  context '#superset' do
    it 'should return all ancestors and the current class, in order' do
      @x.superset.should == [@x, ClassRegistry['Object']]
      @y.superset.should == [@y, @x, ClassRegistry['Object']]
      @y2.superset.should == [@y2, @x, ClassRegistry['Object']]
      @z.superset.should == [@z, @y, @x, ClassRegistry['Object']]
      @w.superset.should == [@w, @y2, @x, ClassRegistry['Object']]
    end
  end
  
  context '#proper_superset' do
    it 'should return all ancestors, in order' do
      @x.proper_superset.should == [ClassRegistry['Object']]
      @y.proper_superset.should == [@x, ClassRegistry['Object']]
      @y2.proper_superset.should == [@x, ClassRegistry['Object']]
      @z.proper_superset.should == [@y, @x, ClassRegistry['Object']]
      @w.proper_superset.should == [@y2, @x, ClassRegistry['Object']]
    end
  end
  
  context '#subset' do
    it 'should return all known classes in the class tree rooted at the receiver' do
      @w.subset.should == [@w]
      @z.subset.should == [@z]
      @y2.subset.should == [@y2, @w]
      @y.subset.should == [@y, @z]
      @x.subset.should == [@x, @y, @z, @y2, @w]
    end
  end
  
  context '#proper_subset' do
    it 'should return all known classes in the class tree rooted at the receiver' do
      @w.proper_subset.should == []
      @z.proper_subset.should == []
      @y2.proper_subset.should== [@w]
      @y.proper_subset.should == [@z]
      @x.proper_subset.should == [@y, @z, @y2, @w]
    end
  end
end

describe WoolMethod do
  extend AnalysisHelpers
  clean_registry

  before do
    @a = WoolClass.new('A')
    @b = WoolClass.new('B')
    @method = WoolMethod.new('foobar')
  end
  
  context '#add_signature' do
    it 'creates signature objects and returns them in #signatures' do
      @method.add_signature(Signature.new('foobar', @a.protocol, []))
      @method.add_signature(Signature.new('foobar', @b.protocol,
          [Argument.new('a', :positional, @a.protocol),
           Argument.new('a2', :positional, @a.protocol)]))
      @method.signatures.should include(Signature.new('foobar', @a.protocol, []))
      @method.signatures.should include(
          Signature.new('foobar', @b.protocol,
              [Argument.new('a', :positional, @a.protocol),
               Argument.new('a2', :positional, @a.protocol)]))
    end
  end
  
  context '#name' do
    it 'returns the name' do
      @method.name.should == 'foobar'
    end
  end
end