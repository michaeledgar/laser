require_relative 'spec_helper'

describe Parsers::ClassParser do
  before do
    @parser = Parsers::AnnotationParser.new
  end
  
  describe 'a simple class name' do
    it 'is parsed into a single covariant constraint' do
      'Hello'.should parse_to(Types::ClassType.new('Hello', :covariant))
      'Hello'.should_not parse_to(Types::ClassType.new('Hello', :contravariant))
    end
  end
  
  describe 'the Boolean shorthand' do
    it 'is parsed as the union of TrueClass and FalseClass' do
      'Boolean'.should parse_to(Types::UnionType.new([Types::TRUECLASS, Types::FALSECLASS]))
    end
  end
  
  describe "a complex class path" do
    it "is parsed into a single covariant constraint" do
      '::Hello::World::Is::Here'.should parse_to(
          Types::ClassType.new('::Hello::World::Is::Here', :covariant))
    end
  end
  
  describe 'a class name followed by -' do
    it "is parsed into a contravariant class constraint" do
      'World::Is::Here-'.should parse_to(
          Types::ClassType.new('World::Is::Here', :contravariant))
    end
  end
  
  describe 'a class name followed by =' do
    it "is parsed into a contravariant class constraint" do
      'World::Is::Here='.should parse_to(
          Types::ClassType.new('World::Is::Here', :invariant))
    end
  end
  
  describe 'two constraints separated by =>' do
    it 'is parsed as a Hash<C1, C2>' do
      ['Symbol => String', 'Symbol=>String', 'Symbol  =>   String'].each do |input|
        input.should parse_to(
            Types::GenericType.new(Types::ClassType.new('Hash', :covariant),
                [Types::ClassType.new('Symbol', :covariant),
                 Types::ClassType.new('String', :covariant)]))
      end
    end
    
    it 'allows variance constraints on the key and value types' do
      '::Hello::World==>Some::Constant-'.should parse_to(
          Types::GenericType.new(Types::ClassType.new('Hash', :covariant),
              [Types::ClassType.new('::Hello::World', :invariant),
               Types::ClassType.new('Some::Constant', :contravariant)]))
    end
  end
  
  describe 'a generic Array definition' do
    it 'is parsed as a GenericType' do
      'Array<String>'.should parse_to(
          Types::GenericType.new(Types::ClassType.new('Array', :covariant),
              [Types::ClassType.new('String', :covariant)]))
    end
  end
  
  describe 'a generic Hash definition' do
    it 'is parsed as a GenericType' do
      'Hash- < Symbol=,   String  >'.should parse_to(
          Types::GenericType.new(Types::ClassType.new('Hash', :contravariant),
              [Types::ClassType.new('Symbol', :invariant),
               Types::ClassType.new('String', :covariant)]))
    end
  end
  
  describe 'a nested generic definition' do
    it 'should parse correctly as nested GenericType' do
      'Array<Hash<Symbol, String>>'.should parse_to(
          Types::GenericType.new(Types::ClassType.new('Array', :covariant),
              [Types::GenericType.new(Types::ClassType.new('Hash', :covariant),
                  [Types::ClassType.new('Symbol', :covariant),
                   Types::ClassType.new('String', :covariant)])]))
    end
  end
  
  describe 'an array generic shorthand' do
    it 'should parse as a covariant generic array constraint' do
      '[   String= ]'.should parse_to(
          Types::GenericType.new(Types::ClassType.new('Array', :covariant),
              [Types::ClassType.new('String', :invariant)]))
    end
  end
  
  describe 'a dont-care shorthand' do
    it 'should parse as a covariant Object constraint, which matches any object' do
      '_'.should parse_to(Types::ClassType.new('Object', :covariant))
    end
  end

  describe 'tuples' do
    describe 'a simple tuple type' do
      it 'should parse to a TupleType' do
        '(String- , _ , Symbol= => Fixnum)'.should parse_to(
            Types::TupleType.new(
              [Types::ClassType.new('String', :contravariant),
               Types::ClassType.new('Object', :covariant),
               Types::GenericType.new(Types::ClassType.new('Hash', :covariant),
                   [Types::ClassType.new('Symbol', :invariant),
                    Types::ClassType.new('Fixnum', :covariant)])]))
      end
    end
  
    describe 'an empty tuple type' do
      it 'should parse to a (relatively useless) TupleType' do
        '(  )'.should parse_to(Types::TupleType.new([]))
      end
    end
  end
end