require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SexpAnalysis do
  describe SexpAnalysis::Sexp do
    before do
      @sexp = SexpAnalysis::Sexp.new([:if, [:abc, 2, 3], [:def, 4, 5], nil])
    end
    
    describe '#type' do
      it 'returns the type of the sexp' do
        @sexp.type.should == :if
        @sexp[1].type.should == :abc
        @sexp[2].type.should == :def
      end
    end
    
    describe '#children' do
      it 'returns the children of a normal sexp' do
        @sexp.children.should == [[:abc, 2, 3], [:def, 4, 5], nil]
        @sexp[1].children.should == [2, 3]
        @sexp[2].children.should == [4, 5]
      end
      
      it 'returns everything in an array if a whole-array sexp' do
        SexpAnalysis::Sexp.new([[:abc], 2, 3, [:def, 3, 4]]).children.should == [[:abc], 2, 3, [:def, 3, 4]]
      end
    end
    
    context 'with annotations' do
      describe '#initialize' do
        before do
          annotator_1, annotator_2 = Object.new, Object.new
          def annotator_1.annotate!(node)
            x = node[0]
            def x.weird_thing!
              "silly!"
            end
            def x.weird_thing_2!
              "hello"
            end
          end
          def annotator_2.annotate!(node)
            x = node[0]
            def x.weird_thing_2!
              "world"
            end
          end
          @old_annotations, SexpAnalysis::Sexp.annotations = SexpAnalysis::Sexp.annotations, [annotator_1, annotator_2]
        end
        
        after do
          SexpAnalysis::Sexp.annotations = @old_annotations
        end
        
        it 'runs the annotators in order' do
          x = Object.new
          def x.name; "x"; end
          result = SexpAnalysis::Sexp.new([x])
          x.weird_thing!.should == "silly!"
          x.weird_thing_2!.should == "world"
        end
      end
    end
  end
  
  
  before do
    @class = Class.new do
      include SexpAnalysis
      attr_accessor :body
      def initialize(body)
        self.body = body
      end
    end
  end

  context '#parse' do
    it 'parses its body' do
      @class.new('a').parse.should ==
          [:program, [[:var_ref, [:@ident, "a", [1, 0]]]]]
    end
  end

  context '#find_sexps' do
    it 'searches its body' do
      @class.new('a + b').find_sexps(:binary).should_not be_empty
    end

    it 'returns an empty array if no sexps are found' do
      @class.new('a + b').find_sexps(:rescue).should be_empty
    end
  end
end