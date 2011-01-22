require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Parsers::ClassParser do
  before do
    @parser = Parsers::AnnotationParser.new
  end
  
  describe 'a simple class name' do
    it 'is parsed into a single covariant constraint' do
      'Hello'.should parse_to([Constraints::ClassConstraint.new('Hello', :covariant)])
      'Hello'.should_not parse_to([Constraints::ClassConstraint.new('Hello', :contravariant)])
    end
  end
  
  describe "a complex class path" do
    it "is parsed into a single covariant constraint" do
      '::Hello::World::Is::Here'.should parse_to(
          [Constraints::ClassConstraint.new('::Hello::World::Is::Here', :covariant)])
    end
  end
  
  describe 'a class name followed by -' do
    it "is parsed into a contravariant class constraint" do
      'World::Is::Here-'.should parse_to(
          [Constraints::ClassConstraint.new('World::Is::Here', :contravariant)])
    end
  end
  
  describe 'a class name followed by =' do
    it "is parsed into a contravariant class constraint" do
      'World::Is::Here='.should parse_to(
          [Constraints::ClassConstraint.new('World::Is::Here', :invariant)])
    end
  end
  
  describe 'two constraints separated by =>' do
    it 'is parsed as a Hash<C1, C2>' do
      ['Symbol => String', 'Symbol=>String', 'Symbol  =>   String'].each do |input|
        input.should parse_to(
            [Constraints::GenericClassConstraint.new('Hash', :covariant,
                [Constraints::ClassConstraint.new('Symbol', :covariant),
                 Constraints::ClassConstraint.new('String', :covariant)])])
      end
    end
    
    it 'allows variance constraints on the key and value types' do
      '::Hello::World==>Some::Constant-'.should parse_to(
          [Constraints::GenericClassConstraint.new('Hash', :covariant,
              [Constraints::ClassConstraint.new('::Hello::World', :invariant),
               Constraints::ClassConstraint.new('Some::Constant', :contravariant)])])
    end
  end
  
  describe 'a generic Array definition' do
    it 'is parsed as a GenericClassConstraint' do
      'Array<String>'.should parse_to(
          [Constraints::GenericClassConstraint.new('Array', :covariant,
              [Constraints::ClassConstraint.new('String', :covariant)])])
    end
  end
  
  describe 'a generic Hash definition' do
    it 'is parsed as a GenericClassConstraint' do
      'Hash- < Symbol=,   String  >'.should parse_to(
          [Constraints::GenericClassConstraint.new('Hash', :contravariant,
              [Constraints::ClassConstraint.new('Symbol', :invariant),
               Constraints::ClassConstraint.new('String', :covariant)])])
    end
  end
  
  describe 'a nested generic definition' do
    it 'should parse correctly as nested GenericClassConstraint' do
      'Array<Hash<Symbol, String>>'.should parse_to(
          [Constraints::GenericClassConstraint.new('Array', :covariant,
              [Constraints::GenericClassConstraint.new('Hash', :covariant,
                  [Constraints::ClassConstraint.new('Symbol', :covariant),
                   Constraints::ClassConstraint.new('String', :covariant)])])])
    end
  end
  
  describe 'an array generic shorthand' do
    it 'should parse as a covariant generic array constraint' do
      '[   String= ]'.should parse_to(
          [Constraints::GenericClassConstraint.new('Array', :covariant,
              [Constraints::ClassConstraint.new('String', :invariant)])])
    end
  end
  
  describe 'a dont-care shorthand' do
    it 'should parse as a covariant Object constraint, which matches any object' do
      '_'.should parse_to(
          [Constraints::ClassConstraint.new('Object', :covariant)])
    end
  end
end