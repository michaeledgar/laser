require 'set'
require_relative 'spec_helper'

describe ControlFlow::Instruction do
  describe '#explicit_targets' do
    before do
      @temp = Bindings::TemporaryBinding.new('%t1', nil)
      @call_target = Bindings::TemporaryBinding.new('%t2', nil)
      @ary = Bindings::TemporaryBinding.new('%t3', nil)
    end

    it 'should return an empty set for a return node' do
      ControlFlow::Instruction.new([:return, 1, 2]).
          explicit_targets.should == ::Set[]
    end

    it 'should return an empty set for a jump node' do
      ControlFlow::Instruction.new([:jump, 'B1']).
          explicit_targets.should == ::Set[]
    end

    it 'should return an empty set for a branch node' do
      ControlFlow::Instruction.new([:branch, 't1', 'b2', 'b3']).
          explicit_targets.should == ::Set[]
    end
    
    it 'should return the target for an assign instruction' do
      ControlFlow::Instruction.new([:assign, @temp, 2]).
          explicit_targets.should == ::Set[@temp]
    end

    it 'should return the target for a call instruction' do
      ControlFlow::Instruction.new([:call, @call_target, @temp, 'to_i', :block => false]).
          explicit_targets.should == ::Set[@call_target]
    end
    
    it 'should return the target for a call_vararg instruction' do
      ControlFlow::Instruction.new([:call_vararg, @call_target, @temp, 'to_i', @ary, :block => false]).
          explicit_targets.should == ::Set[@call_target]
    end

    it 'should return the target for a super instruction' do
      ControlFlow::Instruction.new([:super, @call_target, :block => false]).
          explicit_targets.should == ::Set[@call_target]
    end
    
    it 'should return the target for a super_vararg instruction' do
      ControlFlow::Instruction.new([:super_vararg, @call_target, @ary, :block => false]).
          explicit_targets.should == ::Set[@call_target]
    end
    
    it 'should return the target for a lambda instruction' do
      ControlFlow::Instruction.new([:lambda, @temp, 'B2']).
          explicit_targets.should == ::Set[@temp]
    end
  end

  describe '#operands' do
    before(:all) do
      @temp = Bindings::TemporaryBinding.new('%t1', nil)
      @call_target = Bindings::TemporaryBinding.new('%t2', nil)
      @ary = Bindings::TemporaryBinding.new('%t3', nil)
      @temp_2 = Bindings::TemporaryBinding.new('%t4', nil)
    end

    it 'should return a set with the returned value for a return node' do
      ControlFlow::Instruction.new([:return, @temp]).
          operands.should == [@temp]
    end

    it 'should return an empty set for a jump node' do
      ControlFlow::Instruction.new([:jump, 'B1']).
          operands.should == []
    end

    it 'should return a set with the branched-on value for a branch node' do
      ControlFlow::Instruction.new([:branch, @temp, 'b2', 'b3']).
          operands.should == [@temp]
    end
    
    it 'should return the value temporary for an assign instruction' do
      ControlFlow::Instruction.new([:assign, @temp, @ary]).
          operands.should == [@ary]
    end

    it 'should return the receiver and arguments for a call instruction' do
      ControlFlow::Instruction.new([:call, @call_target, @temp, 'to_i', @temp_2, :block => false]).
          operands.should == [@temp, @temp_2]
    end
    
    it 'should return the receiver and arguments for a call_vararg instruction' do
      ControlFlow::Instruction.new([:call_vararg, @call_target, @temp, 'to_i', @ary, :block => false]).
          operands.should == [@temp, @ary]
    end

    it 'should return the arguments for a super instruction' do
      ControlFlow::Instruction.new([:super, @call_target, @temp_2, :block => false]).
          operands.should == [@temp_2]
    end
    
    it 'should return the arguments for a super_vararg instruction' do
      ControlFlow::Instruction.new([:super_vararg, @call_target, @ary, :block => false]).
          operands.should == [@ary]
    end
    
    it 'should return the empty set for a lambda instruction' do
      ControlFlow::Instruction.new([:lambda, @temp, 'B2']).
          operands.should == []
    end
  end
end
