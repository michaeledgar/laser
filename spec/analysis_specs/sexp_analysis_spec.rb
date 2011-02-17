require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SexpAnalysis do  
  before do
    @class = Class.new do
      include SexpAnalysis
      attr_accessor :body
      def initialize(body)
        self.body = body
      end
    end
  end

  describe '#parse' do
    it 'parses its body' do
      @class.new('a').parse.should ==
          [:program, [[:var_ref, [:@ident, "a", [1, 0]]]]]
    end
  end

  describe '#find_sexps' do
    it 'searches its body' do
      @class.new('a + b').find_sexps(:binary).should_not be_empty
    end

    it 'returns an empty array if no sexps are found' do
      @class.new('a + b').find_sexps(:rescue).should be_empty
    end
  end
end