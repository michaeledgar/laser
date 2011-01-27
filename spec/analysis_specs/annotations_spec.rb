require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe BasicAnnotation do
  before(:each) do
    @global_annotations = Annotations.global_annotations.dup
    Annotations.global_annotations = []
    @class = Class.new(BasicAnnotation) do
      def annotate!(node)
        node[0] = (node[0].to_s + 'lolz').intern
      end
    end
  end

  after(:each) do
    Annotations.global_annotations.replace @global_annotations
  end

  describe '#add_global_annotator' do
    it 'adds the given argument to the list of global annotations' do
      foo = Class.new
      @class.add_global_annotator foo
      Annotations.global_annotations.last.should be_a(foo)
    end
  end
  
  describe '#add_property' do
    selectors = [:aaa, :aaa=, :bbb, :bbb=]
    it 'adds accessors to SexpAnalysis::Sexp in a very intrusive manner' do
      @class.add_property :aaa, :bbb
      sexp = Sexp.new([:program, []])
      selectors.each {|sel| sexp.should respond_to(sel)}
    end
    after do
      selectors.each {|sel| Sexp.__send__(:undef_method, sel)}
    end
  end
  
  describe '#add_computed_property' do
    it 'adds a no-arg method that computes a property' do
      @class.add_computed_property(:childsize) { self.children.size }
      @class.add_global_annotator(@class)
      sexp = Sexp.new([:abc, :cde, :aaa, :bbb, [:hi, 1, 2]])
      sexp.childsize.should == 4
      sexp.children[3].childsize.should == 2
    end
  end
end