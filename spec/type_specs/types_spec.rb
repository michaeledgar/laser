require_relative 'spec_helper'

describe Types do
  describe '.subtype?' do
    describe 'invariant class types' do
      it 'should include itself' do
        Types.subtype?(Types::ClassType.new('Integer', :invariant),
                       Types::ClassType.new('Integer', :invariant)).should be true
      end
      
      it 'should not include subclasses' do
        Types.subtype?(Types::ClassType.new('Fixnum', :invariant),
                       Types::ClassType.new('Integer', :invariant)).should be false
      end
      
      it 'should not include superclasses' do
        Types.subtype?(Types::ClassType.new('Numeric', :invariant),
                       Types::ClassType.new('Integer', :invariant)).should be false
      end
    end
    
    describe 'covariant class types' do
      it 'should include itself' do
        Types.subtype?(Types::ClassType.new('Integer', :invariant),
                       Types::ClassType.new('Integer', :covariant)).should be true
      end
      
      it 'should include subclasses' do
        Types.subtype?(Types::ClassType.new('Fixnum', :invariant),
                       Types::ClassType.new('Integer', :covariant)).should be true
      end
      
      it 'should not include superclasses' do
        Types.subtype?(Types::ClassType.new('Numeric', :invariant),
                       Types::ClassType.new('Integer', :covariant)).should be false
      end
      
      it 'should include a union of subclasses' do
        Types.subtype?(Types::UnionType.new(
                         [Types::ClassType.new('Integer', :invariant),
                          Types::ClassType.new('Float',  :invariant)]),
                       Types::ClassType.new('Numeric', :covariant)).should be true
      end
    end

    describe 'contravariant class types' do
      it 'should include itself' do
        Types.subtype?(Types::ClassType.new('Integer', :invariant),
                       Types::ClassType.new('Integer', :contravariant)).should be true
      end
      
      it 'should not include subclasses' do
        Types.subtype?(Types::ClassType.new('Fixnum', :invariant),
                       Types::ClassType.new('Integer', :contravariant)).should be false
      end
      
      it 'should include superclasses' do
        Types.subtype?(Types::ClassType.new('Numeric', :invariant),
                       Types::ClassType.new('Integer', :contravariant)).should be true
      end
    end
    
    describe 'union types' do
      it 'should include member types' do
        Types.subtype?(Types::ClassType.new('Integer', :invariant),
                       Types::UnionType.new(
                         [Types::ClassType.new('Integer', :invariant),
                          Types::ClassType.new('String',  :invariant)])).should be true
      end
    end
  end
  describe Types::TOP do
    it 'should be equal to a covariant BasicObject instance' do
      Types::TOP.should == Types::ClassType.new('BasicObject', :covariant)
    end
  end
  
  describe Types::UnionType do
    it 'should compare equal despite member type ordering' do
      Types::UnionType.new([Types::STRING, Types::FIXNUM, Types::ARRAY]).should ==
        Types::UnionType.new([Types::ARRAY, Types::STRING, Types::FIXNUM])
    end
  end

  describe Types::ClassType do
    describe '#possible_classes' do
      it 'should find subclasses if the ClassType is covariant and is a Class' do
        Types::ClassType.new('Integer', :covariant).possible_classes.should ==
            ::Set[ClassRegistry['Integer'], ClassRegistry['Fixnum'], ClassRegistry['Bignum']]
      end
      
      it 'should find the exact class ClassType is invariant and is a Class' do
        Types::ClassType.new('Integer', :invariant).possible_classes.should ==
            ::Set[ClassRegistry['Integer']]
      end
      
      it 'should find superclasses if the ClassType is invariant and is a Class' do
        Types::ClassType.new('Fixnum', :contravariant).possible_classes.should ==
            ::Set[ClassRegistry['Fixnum'], ClassRegistry['Integer'], ClassRegistry['Numeric'],
                  ClassRegistry['Object'], ClassRegistry['BasicObject']]
      end
      
      it 'should find classes including the module if the ClassType is covariant and is a Module' do
        Types::ClassType.new('Kernel', :covariant).possible_classes.should ==
            ::Set.new(ClassRegistry['Object'].subset)
        comparables = Types::ClassType.new('Comparable', :covariant).possible_classes
        %w(String Numeric Integer Fixnum Bignum Float).each do |comparable|
          comparables.should include(ClassRegistry[comparable])
        end
      end
    end
    
    describe '#matching_methods' do
      it 'should search the possible classes for instance methods of the same name (covariant)' do
        Types::ClassType.new('Integer', :covariant).matching_methods('modulo').should ==
            [ClassRegistry['Numeric'].instance_method('modulo'),
             ClassRegistry['Fixnum'].instance_method('modulo'),
             ClassRegistry['Bignum'].instance_method('modulo')]
      end
      
      it 'should search the possible classes for instance methods of the same name (invariant)' do
        Types::ClassType.new('Integer', :invariant).matching_methods('odd?').should ==
            [ClassRegistry['Integer'].instance_method('odd?')]
      end
      
      it 'should search the possible classes for instance methods of the same name (contravariant)' do
        Types::ClassType.new('Bignum', :contravariant).matching_methods('odd?').should ==
            [ClassRegistry['Bignum'].instance_method('odd?'),
             ClassRegistry['Integer'].instance_method('odd?')]
      end
    end
  end
end
