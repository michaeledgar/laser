require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Parsers::ClassParser do
  before do
    @parser = Parsers::ClassParser.new
  end
  
  describe 'a simple class name' do
    it 'is parsed into a single covariant constraint' do
      @parser.parse('Hello').constraints.should ==
          [Constraints::ClassConstraint.new('Hello', :covariant)]
    end
  end
  
  describe "a complex class path" do
    it "is parsed into a single covariant constraint" do
      @parser.parse('::Hello::World::Is::Here').constraints.should ==
          [Constraints::ClassConstraint.new('::Hello::World::Is::Here', :covariant)]
    end
  end
  
  describe 'a class name followed by -' do
    it "is parsed into a contravariant class constraint" do
      @parser.parse('World::Is::Here-').constraints.should ==
          [Constraints::ClassConstraint.new('World::Is::Here', :contravariant)]
    end
  end
  
  describe 'a class name followed by =' do
    it "is parsed into a contravariant class constraint" do
      @parser.parse('World::Is::Here=').constraints.should ==
          [Constraints::ClassConstraint.new('World::Is::Here', :invariant)]
    end
  end
  
  describe 'two constraints separated by =>' do
    it 'is parsed as a Hash<C1, C2>' do
      ['Symbol => String', 'Symbol=>String', 'Symbol  =>   String'].each do |input|
        @parser.parse(input).constraints.should ==
            [Constraints::GenericClassConstraint.new('Hash', :covariant,
                [Constraints::ClassConstraint.new('Symbol', :covariant)],
                [Constraints::ClassConstraint.new('String', :covariant)])]
      end
    end
    
    it 'allows variance constraints on the key and value types' do
      @parser.parse('::Hello::World==>Some::Constant-').constraints.should ==
          [Constraints::GenericClassConstraint.new('Hash', :covariant,
              [Constraints::ClassConstraint.new('::Hello::World', :invariant)],
              [Constraints::ClassConstraint.new('Some::Constant', :contravariant)])]
    end
  end
end