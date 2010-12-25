require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ActsAsStruct do
  members = :first, :second, :third, :fourth, :fifth
  values = 1, 2, 3, 4, 5
  zipped = members.zip(values)
  derived_members = members + [:sixth, :seventh]
  derived_values = values + [6, 7]
  derived_zipped = derived_members.zip(derived_values)
  
  before do
    @class = Class.new do
      extend ActsAsStruct
      acts_as_struct *members
    end
    @instance = @class.new(*values)
    @derived_class = Class.new(@class) do
      acts_as_struct(*(derived_members - members))
    end
    @derived_instance = @derived_class.new(*derived_values)
  end

  describe '#acts_as_struct' do
    it 'creates readers for all named attributes' do
      members.each { |member| @instance.should respond_to(member) }
    end

    it 'creates writers for all named attributes' do
      members.each { |member| @instance.should respond_to("#{member}=") }
    end
    
    describe '#initialize' do
      it 'allows initialization via positional arguments' do
        zipped.each { |member, value| @instance.send(member).should == value }
      end
    
      it 'allows initialization with a hash' do
        instance = @class.new(Hash[zipped.flatten])
        zipped.each { |member, value| @instance.send(member).should == value }
      end
    
      it 'allows fewer positional arguments than the maximum' do
        instance = @class.new(1)
        instance.first.should == 1
        instance.third.should == nil
      end
    
      it 'raises on too many positional arguments' do
        lambda { @class.new(1,2,3,4,5,6) }.should raise_error(ArgumentError)
      end
    end
    
    describe '#keys' do
      it 'returns the keys used in acts_as_struct' do
        @instance.keys.should == members
      end
    end
    
    describe '#values' do
      it 'returns the values in the same order as used in acts_as_struct' do
        @instance.values.should == values
      end
    end
    
    describe '#keys_and_values' do
      it 'returns the keys and values arrays zipped' do
        @instance.keys_and_values.should == zipped
      end
    end
    
    describe '#each' do
      it 'yields each key and value in order' do
        yielded_values = []
        @instance.each { |k, v| yielded_values << [k, v] }
        yielded_values.should == zipped
      end
    end
    
    describe '#<=>' do
      it 'compares the values pairwise, in the order given by the acts_as_struct call' do
        @class.new(1,2,3).should be < @class.new(2,2,3)
        @class.new(1,2,3).should be < @class.new(1,2,4)
        @class.new(1,2,3).should be == @class.new(1,2,3)
        @class.new(4,4,5).should be > @class.new(4,4,4)
      end
    end
    
    describe 'when used in a derived class that is also using acts_as_struct' do
      it 'should simply append the new members to create a compatible subtype' do
        @derived_instance.keys_and_values.should == derived_zipped
      end
    end
  end
end