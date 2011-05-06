require File.dirname(__FILE__) + '/spec_helper'

describe 'standard library exceptions' do
  %w(Exception StandardError IOError TypeError ScriptError SystemExit
     SignalException Interrupt ArgumentError IndexError KeyError
     RangeError SyntaxError LoadError NotImplementedError NameError
     NoMethodError RuntimeError SecurityError NoMemoryError EncodingError
     SystemCallError ZeroDivisionError FloatDomainError RegexpError EOFError
     LocalJumpError SystemStackError).each do |error|
    it "should define a constant named #{error} at the top level" do
      ClassRegistry['Object'].const_get(error).should be_a(LaserClass)
    end
    
    it "should define #{error} as a class with Exception in its superset" do
      klass = ClassRegistry['Object'].const_get(error)
      klass.superset.should include(ClassRegistry['Exception'])
    end
  end
end