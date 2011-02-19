require File.dirname(__FILE__) + '/spec_helper'

describe 'standard library exceptions' do
  %w(Exception StandardError IOError TypeError ScriptError SystemExit
     SignalException Interrupt ArgumentError IndexError KeyError
     RangeError SyntaxError LoadError NotImplementedError NameError
     NoMethodError RuntimeError SecurityError NoMemoryError EncodingError
     SystemCallError ZeroDivisionError FloatDomainError RegexpError EOFError
     LocalJumpError SystemStackError).each do |error|
    it "should define a constant named #{error} at the top level" do
      Scope::GlobalScope.lookup(error).should be_a(Bindings::ConstantBinding)
    end
    
    it "should define #{error} as a class with Exception in its superset" do
      klass = Scope::GlobalScope.lookup(error).value
      klass.superset.should include(ClassRegistry['Exception'])
    end
  end
end