require_relative 'spec_helper'

describe Error do
  it 'is a StandardError subclass' do
    Error.ancestors.should include(StandardError)
  end

  describe '#initialize' do
    it 'assigns a message, an AST node, and a severity' do
      result = Error.new('msg here', [:lol], 3)
      result.message.should == 'msg here'
      result.ast_node.should == [:lol]
      result.severity.should == 3
    end
  end
  
  context 'when subclassed' do
    before do
      @temp_class = Class.new(Error) do
        severity 3
      end
    end
    it 'has a class-level severity method for specifying a constant severity' do
      result = @temp_class.new('a', [:hi])
      result.message.should == 'a'
      result.ast_node.should == [:hi]
      result.severity.should == 3
    end
  end
end