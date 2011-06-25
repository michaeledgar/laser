require_relative 'spec_helper'

describe Laser do
  it "has a version" do
    VERSION.should_not be_nil
    VERSION.should >= "0.5.0"
  end
  
  describe 'TESTS_ACTIVATED' do
    it 'should be true' do
      TESTS_ACTIVATED.should be true
    end
  end
end