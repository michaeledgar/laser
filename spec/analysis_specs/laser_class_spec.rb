require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe LaserObject do
  before do
    @instance = LaserObject.new(ClassRegistry['Array'])
  end
  
  it 'defaults to the global scope' do
    @instance.scope.should == Scope::GlobalScope
  end
  
  describe '#add_instance_method!' do
    it 'should add the method to its singleton class' do
      @instance.add_instance_method!(LaserMethod.new('abcdef') do |method|
        method.add_signature!(Signature.new('abcdef', [], Types::TOP))
      end)
      @instance.signatures.should include(
          Signature.new('abcdef', [], Types::TOP))
      @instance.singleton_class.instance_signatures.should include(
          Signature.new('abcdef', [], Types::TOP))
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
    @name = if described_class == LaserModule then 'Module'
            elsif described_class == LaserClass then 'Class'
            end
    @a = described_class.new(ClassRegistry[@name], Scope::GlobalScope, 'A')
    @b = described_class.new(ClassRegistry[@name], Scope::GlobalScope, 'B') do |b|
      b.add_instance_method!(LaserMethod.new('foo') do |method|
        method.add_signature!(Signature.new('foo', [], Types::ClassType.new(@a.path, :covariant)))
        method.add_signature!(Signature.new('foo',
            [Bindings::ArgumentBinding.new('a', LaserObject.new(@a), :positional)],
            Types::ClassType.new(b.path, :covariant)))
      end)
      b.add_instance_method!(LaserMethod.new('bar') do |method|
        method.add_signature!(Signature.new('bar',
            [Bindings::ArgumentBinding.new('a', LaserObject.new(@a), :positional),
             Bindings::ArgumentBinding.new('b', LaserObject.new(b), :positional)],
            Types::ClassType.new(b.path, :covariant)))
      end)
    end
  end
  
  describe '#initialize' do
    it 'should raise if the path contains a component that does not start with a capital' do
      expect { described_class.new(ClassRegistry[@name], Scope::GlobalScope, '::A::b::C') }.to raise_error(ArgumentError)
    end
    
    it 'should raise if the path has one component that does not start with a capital' do
      expect { described_class.new(ClassRegistry[@name], Scope::GlobalScope, 'acd') }.to raise_error(ArgumentError)
    end
  end
  
  describe '#name' do
    it 'extracts the name from the full path' do
      x = described_class.new(ClassRegistry[@name], Scope::GlobalScope, '::A::B::C::D::EverybodysFavoriteClass')
      x.name.should == 'EverybodysFavoriteClass'
    end
  end
  
  describe '#instance_signatures' do
    it 'returns an empty list when no methods are declared' do
      (@a.signatures - ClassRegistry['Object'].signatures).should be_empty
    end
    
    it "flattens all its normal instance method's signatures" do
      @b.instance_signatures.should include(Signature.new('foo', [], Types::ClassType.new(@a.path, :covariant)))
      @b.instance_signatures.should include(Signature.new('foo',
          [Bindings::ArgumentBinding.new('a', LaserObject.new(@a), :positional)],
          Types::ClassType.new(@b.path, :covariant)))
      @b.instance_signatures.should include(
          Signature.new('bar',
          [Bindings::ArgumentBinding.new('a', LaserObject.new(@a), :positional),
           Bindings::ArgumentBinding.new('b', LaserObject.new(@b), :positional)],
          Types::ClassType.new(@b.path, :covariant)))
    end
  end
  
  describe '#add_signature!' do
    it 'adds the signature to the instance method with the given name' do
      @b.add_signature! Signature.new('foo', [], Types::ClassType.new(@b, :covariant))
      @b.instance_methods['foo'].signatures.should include(
          Signature.new('foo', [], Types::ClassType.new(@b, :covariant)))
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
      LaserModule.new.singleton_class.superclass.should == ClassRegistry['Module']
    end              
  end                
                     
  describe '#include_module' do
    before do
      @a = LaserModule.new
      @b = LaserModule.new
      @c = LaserModule.new
      @d = LaserModule.new
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
      expect { @b.include_module(@a) }.to raise_error(UselessIncludeError)
      @b.ancestors.should == [@b, @a]
      expect { @c.include_module(@a) }.to raise_error(UselessIncludeError)
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
    
    it 'raises on an obvious cyclic include' do
      expect { @a.include_module(@a) }.to raise_error(ArgumentError)
    end
    
    it 'raises on a less-obvious cyclic include' do
      @b.include_module(@a)
      @c.include_module(@b)
      @d.include_module(@c)
      expect { @a.include_module(@d) }.to raise_error(ArgumentError)
    end
    
    it 'raises when including a class' do
      klass = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'X')
      expect { @a.include_module(klass) }.to raise_error(ArgumentError)
    end
    
    it 'does not raise when including an instance of a Module subclass' do
      silly_mod_subclass = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'SillyModSubclass') do |klass|
        klass.superclass = ClassRegistry['Module']
      end
      instance = silly_mod_subclass.get_instance
      @a.include_module(instance)
      @a.ancestors.should == [@a, instance]
    end
  end
end

describe LaserClass do
  it_should_behave_like 'a Ruby module'
  extend AnalysisHelpers
  clean_registry
  
  before do
    @a = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'A')
    @b = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'B') do |b|
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
      @a = LaserModule.new
      @b = LaserModule.new
      @c = LaserModule.new
      @d = LaserModule.new
      @x = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'X')
      @y = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'Y') { |klass| klass.superclass = @x }
      @z = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'Z') { |klass| klass.superclass = @y }
    end                   

    it "inserts the included module into the receiving module's hierarchy when not already there" do
      @x.include_module(@a)
      @x.ancestors.should == [@x, @a, ClassRegistry['Object'],
                              ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
      @y.include_module(@b)
      @y.ancestors.should == [@y, @b, @x, @a, ClassRegistry['Object'],
                              ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
      @z.include_module(@c)
      @z.ancestors.should == [@z, @c, @y, @b, @x, @a, ClassRegistry['Object'],
                              ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
    end
    
    it 'mixes multiple modules into one class' do
      @x.include_module(@a)
      @x.include_module(@b)
      @x.include_module(@c)
      @x.ancestors.should == [@x, @c, @b, @a, ClassRegistry['Object'],
                              ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
    end
    
    it "does nothing when the included module is already in the receiving module's hierarchy" do
      # setup
      @b.include_module(@a)
      @x.include_module(@b)
      @x.ancestors.should == [@x, @b, @a, ClassRegistry['Object'],
                              ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
      # verification
      @y.ancestors.should == [@y, @x, @b, @a, ClassRegistry['Object'],
                              ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
      expect { @y.include_module(@b) }.to raise_error(UselessIncludeError)
      @y.ancestors.should == [@y, @x, @b, @a, ClassRegistry['Object'],
                              ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
    end
    
    it 'only inserts the necessary modules, handling diamond inheritance' do
      # Odd order of operations is intentional here
      @b.include_module(@a)
      @d.include_module(@c)
      @c.include_module(@b)
      
      @x.include_module(@a)
      @y.include_module(@c)
      @z.include_module(@d)
      
      @x.ancestors.should == [@x, @a, ClassRegistry['Object'], ClassRegistry['Kernel'],
                              ClassRegistry['BasicObject']]
      @y.ancestors.should == [@y, @c, @b, @x, @a, ClassRegistry['Object'],
                              ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
      @z.ancestors.should == [@z, @d, @y, @c, @b, @x, @a, ClassRegistry['Object'],
                              ClassRegistry['Kernel'], ClassRegistry['BasicObject']]
    end
  end
end

describe 'hierarchy methods' do
  extend AnalysisHelpers
  clean_registry

  before do
    @y = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'Y')
    @y.superclass = @x = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'X')
    @x.superclass = ClassRegistry['Object']
    @y2 = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'Y2')
    @y2.superclass = @x
    @z = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'Z')
    @z.superclass = @y
    @w = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'W')
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
      @x.superset.should == [@x, ClassRegistry['Object'], ClassRegistry['BasicObject']]
      @y.superset.should == [@y, @x, ClassRegistry['Object'], ClassRegistry['BasicObject']]
      @y2.superset.should == [@y2, @x, ClassRegistry['Object'], ClassRegistry['BasicObject']]
      @z.superset.should == [@z, @y, @x, ClassRegistry['Object'], ClassRegistry['BasicObject']]
      @w.superset.should == [@w, @y2, @x, ClassRegistry['Object'], ClassRegistry['BasicObject']]
    end
  end
  
  describe '#proper_superset' do
    it 'should return all ancestors, in order' do
      @x.proper_superset.should == [ClassRegistry['Object'], ClassRegistry['BasicObject']]
      @y.proper_superset.should == [@x, ClassRegistry['Object'], ClassRegistry['BasicObject']]
      @y2.proper_superset.should == [@x, ClassRegistry['Object'], ClassRegistry['BasicObject']]
      @z.proper_superset.should == [@y, @x, ClassRegistry['Object'], ClassRegistry['BasicObject']]
      @w.proper_superset.should == [@y2, @x, ClassRegistry['Object'], ClassRegistry['BasicObject']]
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
    @a = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'A')
    @b = LaserClass.new(ClassRegistry['Class'], Scope::GlobalScope, 'B')
    @method = LaserMethod.new('foobar')
  end
  
  describe '#add_signature!' do
    it 'creates signature objects and returns them in #signatures' do
      @method.add_signature!(Signature.new('foobar', [], Types::ClassType.new(@a, :covariant)))
      @method.add_signature!(Signature.new('foobar',
          [Bindings::ArgumentBinding.new('a', @a, :positional),
           Bindings::ArgumentBinding.new('a2', @a, :positional)],
          Types::ClassType.new(@b, :covariant)))
      @method.signatures.should include(Signature.new('foobar', [], Types::ClassType.new(@a, :covariant)))
      @method.signatures.should include(
          Signature.new('foobar',
              [Bindings::ArgumentBinding.new('a', @a, :positional),
               Bindings::ArgumentBinding.new('a2', @a, :positional)],
              Types::ClassType.new(@b, :covariant)))
    end
  end
  
  describe '#arity' do
    it 'should compute the arity from the collection of signatures' do
      sexp = Sexp.new(Ripper.sexp('def a(x, a=2, y=3, z, d, &blk); end'))
      signature1 = Signature.for_definition_sexp('a', sexp, Sexp.new([]))
      sexp = Sexp.new(Ripper.sexp('def a(y=3, z, d, &blk); end'))
      signature2 = Signature.for_definition_sexp('a', sexp, Sexp.new([]))
      sexp = Sexp.new(Ripper.sexp('def a(*rest); end'))
      signature3 = Signature.for_definition_sexp('a', sexp, Sexp.new([]))
      @method.add_signature!(signature1)
      @method.arity.should == (3..5)
      @method.add_signature!(signature2)
      @method.arity.should == (2..5)
      @method.add_signature!(signature3)
      @method.arity.should == (0..Float::INFINITY)
    end
  end
  
  describe '#name' do
    it 'returns the name' do
      @method.name.should == 'foobar'
    end
  end
end