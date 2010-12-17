require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe BasicAnnotation do
  before(:each) do
    @annotations = Sexp.annotations.dup
    Sexp.annotations = []
    @global_annotations = SexpAnalysis.global_annotations.dup
    SexpAnalysis.global_annotations = []
    @class = Class.new do
      extend BasicAnnotation
      def annotate!(node)
        node[0] = (node[0].to_s + 'lolz').intern
      end
      add_annotator self
    end
  end

  after(:each) do
    Sexp.annotations.replace @annotations
    SexpAnalysis.global_annotations.replace @global_annotations
  end

  context 'Sexp#initialize' do
    it 'calls all local annotations upon initialization' do
      result = Sexp.new([:foo, [:bar], [:silly]])
      result[0].should == :foololz
      result[1][0].should == :barlolz
      result[2][0].should == :sillylolz
    end
  end

  context '#add_annotator' do
    it 'adds the given argument to the list of annotations' do
      foo = Class.new
      @class.add_annotator foo
      Sexp.annotations.last.should be_a(foo)
    end
  end

  context '#add_global_annotator' do
    it 'adds the given argument to the list of global annotations' do
      foo = Class.new
      @class.add_global_annotator foo
      SexpAnalysis.global_annotations.last.should be_a(foo)
    end
  end
  
  context '#add_property' do
    it 'adds accessors to SexpAnalysis::Sexp in a very intrusive manner' do
      @class.add_property :aaa, :bbb
      sexp = Sexp.new([:program, []])
      sexp.should respond_to(:aaa)
      sexp.should respond_to(:aaa=)
      sexp.should respond_to(:bbb)
      sexp.should respond_to(:bbb=)
      
    end
  end
end