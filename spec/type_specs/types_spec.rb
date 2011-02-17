require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Types do
  describe Types::TOP do
    it 'should be equal to a covariant Object instance' do
      Types::TOP.should == Types::ClassType.new('Object', :covariant)
    end
  end
  describe Types::ClassType do
    describe '#possible_classes' do
      it 'should find subclasses if the ClassType is covariant and is a Class' do
        Types::ClassType.new('Integer', :covariant).possible_classes.should ==
            [ClassRegistry['Integer'], ClassRegistry['Fixnum'], ClassRegistry['Bignum']]
      end
      
      it 'should find the exact class ClassType is invariant and is a Class' do
        Types::ClassType.new('Integer', :invariant).possible_classes.should ==
            [ClassRegistry['Integer']]
      end
      
      it 'should find superclasses if the ClassType is invariant and is a Class' do
        Types::ClassType.new('Fixnum', :contravariant).possible_classes.should ==
            [ClassRegistry['Fixnum'], ClassRegistry['Integer'], ClassRegistry['Numeric'],
             ClassRegistry['Object']]
      end
      
      it 'should find classes including the module if the ClassType is covariant and is a Module' do
        Types::ClassType.new('Kernel', :covariant).possible_classes.should ==
            ClassRegistry['Object'].subset
        comparables = Types::ClassType.new('Comparable', :covariant).possible_classes
        %w(String Numeric Integer Fixnum Bignum Float).each do |comparable|
          comparables.should include(ClassRegistry[comparable])
        end
      end
    end
    
    describe '#matching_methods' do
      it 'should search the possible classes for instance methods of the same name (covariant)' do
        Types::ClassType.new('Integer', :covariant).matching_methods('modulo').should ==
            [ClassRegistry['Numeric'].instance_methods['modulo'],
             ClassRegistry['Fixnum'].instance_methods['modulo'],
             ClassRegistry['Bignum'].instance_methods['modulo']]
      end
      
      it 'should search the possible classes for instance methods of the same name (invariant)' do
        Types::ClassType.new('Integer', :invariant).matching_methods('odd?').should ==
            [ClassRegistry['Integer'].instance_methods['odd?']]
      end
      
      it 'should search the possible classes for instance methods of the same name (contravariant)' do
        Types::ClassType.new('Bignum', :contravariant).matching_methods('odd?').should ==
            [ClassRegistry['Bignum'].instance_methods['odd?'],
             ClassRegistry['Integer'].instance_methods['odd?']]
      end
    end
  end
end