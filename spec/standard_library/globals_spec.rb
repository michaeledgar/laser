require File.dirname(__FILE__) + '/spec_helper'

describe Scope::GlobalScope do
  describe '$:' do
    it 'should be an array' do
      Scope::GlobalScope.lookup('$:').value.should be_a(Array)
    end
    
    it 'should contain the path to standard_library' do
      Scope::GlobalScope.lookup('$:').value.should include(
          File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'laser', 'standard_library')))
    end
  end
end
