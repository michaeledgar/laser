require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool do
  it "has a version" do
    Wool::VERSION.should_not be_nil
    Wool::VERSION.should >= "0.5.0"
  end
end