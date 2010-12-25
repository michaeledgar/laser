require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Parsers::AnnotationParser do
  before do
    @parser = Parsers::AnnotationParser.new
  end
  
  describe 'a self type' do
    it 'should parse as a single self type constraint' do
      @parser.parse('self').constraints.should be ==
          [Constraints::SelfTypeConstraint.new]
    end
  end
  
  describe 'the top type' do
    it 'should have no constraints' do
      @parser.parse('Top').constraints.should be_empty
    end
  end
end