require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe LaserObject do
  before do
    @instance = LaserObject.new(ClassRegistry['Array'])
  end
  
  it 'defaults to the global scope' do
    @instance.scope.should == Scope::GlobalScope
  end
  
  describe '#protocol' do
    it 'should get its protocol from its class' do
      @instance.protocol.should == ClassRegistry['Array'].protocol
    end
  end
  
  describe '#add_instance_method!' do
    it 'should add the method to its singleton class' do
      @instance.add_instance_method!(LaserMethod.new('abcdef') do |method|
        method.add_signature!(Signature.new('abcdef', Protocols::UnknownProtocol.new, []))
      end)
      @instance.signatures.should include(
          Signature.new('abcdef', Protocols::UnknownProtocol.new, []))
      @instance.singleton_class.instance_signatures.should include(
          Signature.new('abcdef', Protocols::UnknownProtocol.new, []))
    end
  end
  
  describe '#singleton_class' do
    it "should return a singleton class with the object's class as its superclass" do
      @instance.singleton_class.superclass == ClassRegistry['Array']
    end
  end
end

shared_examples_for 'a Ruby module' do
  extend AnalysisHelpers
  clean_registry

  before do
    @a = described_class.new('A')
    @b = described_class.new('B') do |b|
      b.add_instance_method!(LaserMethod.new('foo') do |method|
        method.add_signature!(Signature.new('foo', @a.protocol, []))
        method.add_signature!(Signature.new('foo', b.protocol,
            [Bindings::ArgumentBinding.new('a', @a, :positional)]))
      end)
      b.add_instance_method!(LaserMethod.new('bar') do |method|
        method.add_signature!(Signature.new('bar', b.protocol,
            [Bindings::ArgumentBinding.new('a', @a, :positional),
             Bindings::ArgumentBinding.new('b', b, :positional)]))
      end)
    end
  end
  
  describe '#initialize' do
    it 'should raise if the path contains a component that does not start with a capital' do
      expect { described_class.new('::A::b::C') }.to raise_error(ArgumentError)
    end
    
    it 'should raise if the path has one component that does not start with a capital' do
      expect { described_class.new('acd') }.to raise_error(ArgumentError)
    end
  end
  
  describe '#name' do
    it 'extracts the name from the full path' do
      x = described_class.new('::A::B::C::D::EverybodysFavoriteClass')
      x.name.should == 'EverybodysFavoriteClass'
    end
  end
  
  describe '#instance_signatures' do
    it 'returns an empty list when no methods are declared' do
      @a.instance_signatures.should be_empty
    end
    
    it "flattens all its normal instance method's signatures" do
      @b.instance_signatures.should include(Signature.new('foo', @a.protocol, []))
      @b.instance_signatures.should include(Signature.new('foo', @b.protocol,
          [Bindings::ArgumentBinding.new('a', :positional, @a.protocol)]))
      @b.instance_signatures.should include(
          Signature.new('bar', @b.protocol,
          [Bindings::ArgumentBinding.new('a', @a, :positional),
           Bindings::ArgumentBinding.new('b', @b, :positional)]))
    end
  end
  
  describe '#add_signature!' do
    it 'adds the signature to the instance method with the given name' do
      @b.add_signature! Signature.new('foo', @b.protocol, [])
      @b.instance_methods['foo'].signatures.should include(
          Signature.new('foo', @b.protocol, []))
    end
    
    it 'automatically creates the method if it is not already there' do
      @b.add_signature! Signature.new('foomonkey', @b.protocol, [])
      @b.instance_methods['foomonkey'].signatures.should include(
          Signature.new('foomonkey', @b.protocol, []))
    end
  end
  
  describe '#trivial?' do
    it 'returns true if the module has no methods' do
      @a.trivial?.should be true
    end
    
    it 'returns false if the module has an instance method' do
      @b.trivial?.should be false
    end
  end
  
  describe '#nontrivial?' do
    it 'returns false if the module has no methods' do
      @a.nontrivial?.should be false
    end
    
    it 'returns true if the module has an instance method' do
      @b.nontrivial?.should be true
    end
  end
end

describe LaserModule do
  it_should_behave_like 'a Ruby module'
  extend AnalysisHelpers
  clean_registry

  describe '#singleton_class' do
    it 'should return a class with Module as its superclass' do
      LaserModule.new('A').singleton_class.superclass.should == ClassRegistry['Module']
    end
  end
  
  describe '#include_module' do
    before do
      @a = LaserModule.new('A')
      @b = LaserModule.new('B')
      @c = LaserModule.new('C')
      @d = LaserModule.new('D')
    end

    it "inserts the included module into the receiving module's hierarchy when not already there" do
      @b.superclass.should be nil
      @b.include_module(@a)
      @b.ancestors.should == [@b, @a]
    end
    
    it "does nothing when the included module is already in the receiving module's hierarchy" do
      # setup
      @b.include_module(@a)
      @c.include_module(@b)
      @b.ancestors.should == [@b, @a]
      @c.ancestors.should == [@c, @b, @a]
      # verification
      @b.include_module(@a)
      @b.ancestors.should == [@b, @a]
      @c.include_module(@a)
      @c.ancestors.should == [@c, @b, @a]
    end
    
    it "only inserts the necessary modules, handling diamond inheritance" do
      # A has two inherited modules, B and C
      @b.include_module(@a)
      @c.include_module(@a)
      @b.ancestors.should == [@b, @a]
      @c.ancestors.should == [@c, @a]
      # D includes B, then, C, in that order.
      @d.include_module(@b)
      @d.include_module(@c)
      @d.ancestors.should == [@d, @c, @b, @a]
    end
  end
end

describe LaserClass do
  it_should_behave_like 'a Ruby module'
  extend AnalysisHelpers
  clean_registry
  
  before do
    @a = LaserClass.new('A')
    @b = LaserClass.new('B') do |b|
      b.superclass = @a
    end
  end
  
  describe '#singleton_class' do
    it "should have a superclass that is the superclass's singleton class" do
      @b.singleton_class.superclass.should == @a.singleton_class
      @a.singleton_class.superclass.should == ClassRegistry['Object'].singleton_class
    end
  end
  
  describe '#superclass' do
    it 'returns the superclass specified on the LaserClass' do
      @b.superclass.should == @a
    end
  end
  
  describe '#subclasses' do
    it 'returns the set of direct subclasses of the LaserClass' do
      @a.subclasses.should include(@b)
    end
  end
  
  describe '#remove_subclass' do
    it 'allows the removal of direct subclasses (just in case we need to)' do
      @a.remove_subclass!(@b)
      @a.subclasses.should_not include(@b)
    end
  end
  
  describe '#include_module' do
    before do
      @a = LaserModule.new('A')
      @b = LaserModule.new('B')
      @c = LaserModule.new('C')
      @d = LaserModule.new('D')
      @x = LaserClass.new('X')
      @y = LaserClass.new('Y') { |klass| klass.superclass = @x }
      @z = LaserClass.new('Z') { |klass| klass.superclass = @y }
    end

    it "inserts the included module into the receiving module's hierarchy when not already there" do
      @x.include_module(@a)
      @x.ancestors.should == [@x, @a, ClassRegistry['Object']]
      @y.include_module(@b)
      @y.ancestors.should == [@y, @b, @x, @a, ClassRegistry['Object']]
      @z.include_module(@c)
      @z.ancestors.should == [@z, @c, @y, @b, @x, @a, ClassRegistry['Object']]
    end
    
    it "does nothing when the included module is already in the receiving module's hierarchy" do
      # setup
      @b.include_module(@a)
      @x.include_module(@b)
      @x.ancestors.should == [@x, @b, @a, ClassRegistry['Object']]
      # verification
      @y.ancestors.should == [@y, @x, @b, @a, ClassRegistry['Object']]
      @y.include_module(@b)
      @y.ancestors.should == [@y, @x, @b, @a, ClassRegistry['Object']]
    end
    
    it 'only inserts the necessary modules, handling diamond inheritance' do
      # Odd order of operations is intentional here
      @b.include_module(@a)
      @d.include_module(@c)
      @c.include_module(@b)
      
      @x.include_module(@a)
      @y.include_module(@c)
      @z.include_module(@d)
      
      @x.ancestors.should == [@x, @a, ClassRegistry['Object']]
      @y.ancestors.should == [@y, @c, @b, @x, @a, ClassRegistry['Object']]
      @z.ancestors.should == [@z, @d, @y, @c, @b, @x, @a, ClassRegistry['Object']]
    end
  end
end

describe 'hierarchy methods' do
  extend AnalysisHelpers
  clean_registry

  before do
    @y = LaserClass.new('Y')
    @y.superclass = @x = LaserClass.new('X')
    @x.superclass = ClassRegistry['Object']
    @y2 = LaserClass.new('Y2')
    @y2.superclass = @x
    @z = LaserClass.new('Z')
    @z.superclass = @y
    @w = LaserClass.new('W')
    @w.superclass = @y2
  end
  
  describe '#superclass' do
    it 'should return the direct superclass' do
      @x.superclass.should == ClassRegistry['Object']
      @y.superclass.should == @x
      @y2.superclass.should == @x
      @z.superclass.should == @y
      @w.superclass.should == @y2
    end
  end
  
  describe '#superset' do
    it 'should return all ancestors and the current class, in order' do
      @x.superset.should == [@x, ClassRegistry['Object']]
      @y.superset.should == [@y, @x, ClassRegistry['Object']]
      @y2.superset.should == [@y2, @x, ClassRegistry['Object']]
      @z.superset.should == [@z, @y, @x, ClassRegistry['Object']]
      @w.superset.should == [@w, @y2, @x, ClassRegistry['Object']]
    end
  end
  
  describe '#proper_superset' do
    it 'should return all ancestors, in order' do
      @x.proper_superset.should == [ClassRegistry['Object']]
      @y.proper_superset.should == [@x, ClassRegistry['Object']]
      @y2.proper_superset.should == [@x, ClassRegistry['Object']]
      @z.proper_superset.should == [@y, @x, ClassRegistry['Object']]
      @w.proper_superset.should == [@y2, @x, ClassRegistry['Object']]
    end
  end
  
  describe '#subset' do
    it 'should return all known classes in the class tree rooted at the receiver' do
      @w.subset.should == [@w]
      @z.subset.should == [@z]
      @y2.subset.should == [@y2, @w]
      @y.subset.should == [@y, @z]
      @x.subset.should == [@x, @y, @z, @y2, @w]
    end
  end
  
  describe '#proper_subset' do
    it 'should return all known classes in the class tree rooted at the receiver' do
      @w.proper_subset.should == []
      @z.proper_subset.should == []
      @y2.proper_subset.should== [@w]
      @y.proper_subset.should == [@z]
      @x.proper_subset.should == [@y, @z, @y2, @w]
    end
  end
end

describe LaserMethod do
  extend AnalysisHelpers
  clean_registry

  before do
    @a = LaserClass.new('A')
    @b = LaserClass.new('B')
    @method = LaserMethod.new('foobar')
  end
  
  describe '#add_signature!' do
    it 'creates signature objects and returns them in #signatures' do
      @method.add_signature!(Signature.new('foobar', @a.protocol, []))
      @method.add_signature!(Signature.new('foobar', @b.protocol,
          [Bindings::ArgumentBinding.new('a', @a, :positional),
           Bindings::ArgumentBinding.new('a2', @a, :positional)]))
      @method.signatures.should include(Signature.new('foobar', @a.protocol, []))
      @method.signatures.should include(
          Signature.new('foobar', @b.protocol,
              [Bindings::ArgumentBinding.new('a', @a, :positional),
               Bindings::ArgumentBinding.new('a2', @a, :positional)]))
    end
  end
  
  describe '#name' do
    it 'returns the name' do
      @method.name.should == 'foobar'
    end
  end
end