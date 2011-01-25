require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Parsers::ClassParser do
  before do
    @parser = Parsers::AnnotationParser.new
  end
  
  describe 'a simple, full structural constraint' do
    it 'is parsed into a single constraint' do
      '#write(String, Fixnum=) -> NilClass'.should parse_to(
          [Types::StructuralType.new('write',
            [[Types::ClassType.new('String', :covariant)],
             [Types::ClassType.new('Fixnum', :invariant)]],
            [Types::ClassType.new('NilClass', :covariant)])])
    end
    
    it 'parses with an empty arg list' do
      '#write() -> NilClass'.should parse_to(
          [Types::StructuralType.new('write',
            [], [Types::ClassType.new('NilClass', :covariant)])])
    end
  end
  
  describe 'a full structural constraint in Go-style' do
    it 'is parsed into the equivalent constraint' do
      '#write(String) NilClass'.should parse_to(
          [Types::StructuralType.new('write',
            [[Types::ClassType.new('String', :covariant)]],
            [Types::ClassType.new('NilClass', :covariant)])])
    end
    
    it 'parses with an empty arg list' do
      '#write() NilClass'.should parse_to(
          [Types::StructuralType.new('write',
            [], [Types::ClassType.new('NilClass', :covariant)])])
    end
  end
  
  describe 'a structural constraint without a return type' do
    it 'is parsed into a constraint with an empty return type constraint set' do
      '#write(String, Fixnum=)'.should parse_to(
          [Types::StructuralType.new('write',
            [[Types::ClassType.new('String', :covariant)],
             [Types::ClassType.new('Fixnum', :invariant)]],
            [])])
    end
    
    it 'parses with an empty arg list' do
      '#write()'.should parse_to(
          [Types::StructuralType.new('write', [], [])])
    end
  end

  describe 'a structural constraint with an elided argument list' do
    it 'is parsed into a constraint with an empty return type and argument constraint set' do
      '#write->Fixnum-'.should parse_to(
          [Types::StructuralType.new('write', [],
            [Types::ClassType.new('Fixnum', :contravariant)])])
    end
  end
  
  describe 'a structural constraint with no arguments or return types specified' do
    it 'is parsed into a constraint with an empty return type and argument constraint set' do
      '#write'.should parse_to([Types::StructuralType.new('write', [], [])])
    end
  end
end