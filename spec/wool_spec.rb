require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool do
  it "has a version" do
    VERSION.should_not be_nil
    VERSION.should >= "0.5.0"
  end
end