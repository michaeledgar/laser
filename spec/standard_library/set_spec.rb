require File.dirname(__FILE__) + '/spec_helper'

describe 'the Set module' do
  it 'should load fine' do
    tree = annotate_all('require "set"')
    tree.all_errors.should be_empty
    ClassRegistry['Set'].should_not be_nil
  end
end