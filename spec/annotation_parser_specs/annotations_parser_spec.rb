require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Parsers::AnnotationParser do
  before do
    @parser = Parsers::AnnotationParser.new
  end
  
  describe 'a self type' do
    it 'should parse as a single self type constraint' do
      'self'.should parse_to([Types::SelfType.new])
    end
  end
  
  describe 'the top type' do
    it 'should have no constraints' do
      'Top'.should parse_to([])
    end
  end
end