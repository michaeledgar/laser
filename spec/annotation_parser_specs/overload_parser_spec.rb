require_relative 'spec_helper'

describe Parsers::OverloadParser do
  before do
    @parser = Parsers::AnnotationParser.new
  end

  describe 'a simple overload type' do
    it 'is parsed as a generic proc type' do
      '(Float=) -> Float='.should parse_to(
        Types::GenericType.new(
          Types::PROC, [Types::TupleType.new([Types::FLOAT]), Types::FLOAT]))
    end

    it 'is parsed as a generic proc type without the arrow' do
      '(Float=) Float='.should parse_to(
        Types::GenericType.new(
          Types::PROC, [Types::TupleType.new([Types::FLOAT]), Types::FLOAT]))
    end
  end

  describe 'more complex overload listings' do
    it 'is parsed as a generic proc type' do
      '(Float=, Array=, Fixnum=) -> Float= | NilClass='.should parse_to(
        Types::GenericType.new(
          Types::PROC,
          [Types::TupleType.new([Types::FLOAT, Types::ARRAY, Types::FIXNUM]),
           Types::UnionType.new([Types::FLOAT, Types::NILCLASS])]))
    end

    it 'is parsed as a generic proc type without the arrow' do
      '(Float=, Array=, Fixnum=) Float= | NilClass='.should parse_to(
        Types::GenericType.new(
          Types::PROC,
          [Types::TupleType.new([Types::FLOAT, Types::ARRAY, Types::FIXNUM]),
           Types::UnionType.new([Types::FLOAT, Types::NILCLASS])]))
    end
  end
end
