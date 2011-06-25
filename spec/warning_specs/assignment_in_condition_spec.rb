require_relative 'spec_helper'

describe AssignmentInConditionWarning do
  it 'is a file-based warning' do
    AssignmentInConditionWarning.new('(stdin)', 'hello').should be_a(FileWarning)
  end

  context 'in an if condition' do
    it 'matches when the only condition is an unwrapped assignment' do
      AssignmentInConditionWarning.should warn('if x = 5; end')
    end

    it 'does not match if the simple assignment is wrapped in parentheses' do
      AssignmentInConditionWarning.should_not warn('if (x = 5); end')
    end
    
    it 'matches in a complex expression which contains an assignment' do
      AssignmentInConditionWarning.should warn('if (x && y) || x = 5; end')
    end
  end
  
  context 'in an elseif condition' do
    it 'matches when the only condition is an unwrapped assignment' do
      AssignmentInConditionWarning.should warn('if true; elsif x = 5; end')
    end

    it 'does not match if the simple assignment is wrapped in parentheses' do
      AssignmentInConditionWarning.should_not warn('if true; elsif (x = 5); end')
    end
    
    it 'matches in a complex expression which contains an assignment' do
      AssignmentInConditionWarning.should warn('if true; elsif (x && y) || x = 5; end')
    end
  end
  
  context 'in an unless condition' do
    it 'matches when the only condition is an unwrapped assignment' do
      AssignmentInConditionWarning.should warn('unless x = 5; end')
    end

    it 'does not match if the simple assignment is wrapped in parentheses' do
      AssignmentInConditionWarning.should_not warn('unless (x = 5); end')
    end
    
    it 'matches in a complex expression which contains an assignment' do
      AssignmentInConditionWarning.should warn('unless (x && y) || x = 5; end')
    end
  end
  
  it 'is not fooled when the entire if expression is in parentheses' do
    AssignmentInConditionWarning.should warn('(if true; elsif x = 5; end)')
  end

  # it 'does not match when arguments are surrounded by parentheses' do
  #   AssignmentInConditionWarning.should_not warn('def abc(arg); end')
  # end
  # 
  # it 'does not match when there are no arguments' do
  #   AssignmentInConditionWarning.should_not warn('def abc; end')
  # end
  # 
  # describe '#desc' do
  #   it 'includes the name of the offending method' do
  #     matches = AssignmentInConditionWarning.new('(stdin)', 'def silly_monkey arg1, *rest; end').match?
  #     matches[0].desc.should =~ /silly_monkey/
  #   end
  # end
end