require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Parsers::ClassParser do
  before do
    @parser = Parsers::ClassParser.new
  end
  
  context 'a simple class name' do
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
end