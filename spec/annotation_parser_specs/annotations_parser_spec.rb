require_relative 'spec_helper'

describe Parsers::AnnotationParser do
  before do
    @parser = Parsers::AnnotationParser.new
  end
  
  describe 'a self type' do
    it 'should parse as a single self type constraint' do
      'self'.should parse_to(Types::SelfType.new)
    end
  end

  describe 'the top type' do
    it 'should have no constraints' do
      'Top'.should parse_to([])
    end
  end
  
  describe 'union types' do
    it 'should parse to a Types::UnionType instance' do
      'TrueClass= | FalseClass= | NilClass='.should parse_to(
        Types::UnionType.new([
          Types::ClassType.new('TrueClass', :invariant),
          Types::ClassType.new('FalseClass', :invariant),
          Types::ClassType.new('NilClass', :invariant)
        ])
      )
    end
    
    it 'should handle more complicated types' do
      'TrueClass= | #write(#to_s -> String, Integer) -> Boolean'.should parse_to(
        Types::UnionType.new([
          Types::ClassType.new('TrueClass', :invariant),
          Types::StructuralType.new('write', [
            Types::StructuralType.new('to_s', [], Types::ClassType.new('String', :covariant)),
            Types::ClassType.new('Integer', :covariant)
          ], Types::BOOLEAN)
        ])
      )
    end
  end
  
  describe 'named type annotations' do
    it 'should provide a name string' do
      result = @parser.parse('foo: Symbol => Integer')
      result.name.should == 'foo'
    end
    
    it 'should parse the type' do
      result = @parser.parse('foo: Symbol => Integer')
      result.type.should == Types::GenericType.new(Types::ClassType.new('Hash', :covariant),
          [Types::ClassType.new('Symbol', :covariant),
           Types::ClassType.new('Integer', :covariant)])
    end

    it 'should return false for #literal?' do
      result = @parser.parse('foo: Symbol => Integer')
      result.should_not be_literal
    end
    
    it 'should return true for #type?' do
      result = @parser.parse('foo:  Symbol => Integer')
      result.should be_type
    end
  end
  
  describe 'named literal annotations' do
    it 'should provide a name string' do
      result = @parser.parse('foo: nil')
      result.name.should == 'foo'
    end
    
    it 'should parse the literal' do
      result = @parser.parse('foo: nil')
      result.literal.should == nil
    end
    
    it 'should return true for #literal?' do
      result = @parser.parse('foo: nil')
      result.should be_literal
    end
    
    it 'should return false for #type?' do
      result = @parser.parse('foo: nil')
      result.should_not be_type
    end
  end
end
