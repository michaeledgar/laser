require_relative 'spec_helper'

describe SexpAnalysis::ArgumentExpansion do
  describe '#arity' do
    it 'can figure out the arity of a simple method call with no arguments' do
      tree = annotate_all('foo(  )')[1][0][2]
      ArgumentExpansion.new(tree).arity.should == (0..0)
    end

    it 'can figure out the arity of a simple method call' do
      tree = annotate_all('foo(1, 2, 3)')[1][0][2]
      ArgumentExpansion.new(tree).arity.should == (3..3)
    end
    
    it 'does not count block arguments in arity' do
      tree = annotate_all('foo(1, 2, 3, &d())')[1][0][2]
      ArgumentExpansion.new(tree).arity.should == (3..3)
    end
    
    it 'has an infinite maximum arity in the presence of un-computable splats' do
      tree = annotate_all('foo(1, 2, 3, *foobar())')[1][0][2]
      ArgumentExpansion.new(tree).arity.should == (3..Float::INFINITY)
    end
    
    it 'count arguments after splats' do
      tree = annotate_all('foo(1, 2, 3, *foobar(), 4, 5)')[1][0][2]
      ArgumentExpansion.new(tree).arity.should == (5..Float::INFINITY)
    end
    
    it 'splats constant arguments to precise arity' do
      tree = annotate_all('foo(1, 2, 3, *[:a, :b, :c], 4, 5)')[1][0][2]
      ArgumentExpansion.new(tree).arity.should == (8..8)
    end
    
    it 'splats constant range arguments to precise arity' do
      tree = annotate_all('foo(1, 2, 3, *(2...10), 4, 5)')[1][0][2]
      ArgumentExpansion.new(tree).arity.should == (13..13)
    end
  end
  
  describe '#empty?' do
    it 'returns true when no args are being passed' do
      tree = annotate_all('foo(  )')[1][0][2]
      ArgumentExpansion.new(tree).should be_empty
    end
    
    it 'returns false when args are being passed' do
      tree = annotate_all('foo( 2 )')[1][0][2]
      ArgumentExpansion.new(tree).should_not be_empty
    end
  end
  
  describe '#has_block?' do
    it 'returns false with no arguments given' do
      tree = annotate_all('foo()')[1][0][2]
      ArgumentExpansion.new(tree).has_block?.should be false
    end

    it 'returns true if there is an explicit block argument' do
      tree = annotate_all('foo(1, 2, 3, &d)')[1][0][2]
      ArgumentExpansion.new(tree).has_block?.should be_true
    end
    
    it 'returns false if there is an explicit block argument' do
      tree = annotate_all('foo(1, 2, 3, *foobar())')[1][0][2]
      ArgumentExpansion.new(tree).has_block?.should be false
    end
  end
  
  describe '#is_constant?' do
    it 'returns true for no params' do
      tree = annotate_all('foo()')[1][0][2]
      ArgumentExpansion.new(tree).is_constant?.should be_true
    end
    it 'returns true if all constituent arguments are constant' do
      tree = annotate_all('foo(1, 2, 3)')[1][0][2]
      ArgumentExpansion.new(tree).is_constant?.should be_true
    end
    
    it 'returns true if all constituent arguments are constant in the presenece of splats' do
      tree = annotate_all('foo(1, 2, *[1, 2], 4, *("a"..."d"))')[1][0][2]
      ArgumentExpansion.new(tree).is_constant?.should be_true
    end
    
    it 'returns false in the presence of non-constant arguments' do
      tree = annotate_all('foo(1, foobar(), 3)')[1][0][2]
      ArgumentExpansion.new(tree).is_constant?.should be_false
    end
  end

  describe '#constant_values' do
    it 'returns true for no params' do
      tree = annotate_all('foo()')[1][0][2]
      ArgumentExpansion.new(tree).constant_values.should == []
    end
    it 'returns true if all constituent arguments are constant' do
      tree = annotate_all('foo(1, 2, 3)')[1][0][2]
      ArgumentExpansion.new(tree).constant_values.should == [1, 2, 3]
    end
    
    it 'returns true if all constituent arguments are constant in the presence of splats' do
      tree = annotate_all('foo(1, 2, *[1, 2], 4, *("a"..."d"))')[1][0][2]
      ArgumentExpansion.new(tree).constant_values.should == [1, 2, 1, 2, 4, 'a', 'b', 'c']
    end
    
    it 'expands a splatted literal array' do
      tree = annotate_all('foobar *[:a, :b]')[1][0][2]
      expansion = ArgumentExpansion.new(tree)
      expansion.is_constant?.should be_true
      expansion.constant_values.should == [:a, :b]
    end
  end
end
