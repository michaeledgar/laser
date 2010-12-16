require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SexpAnalysis do
  describe Sexp do
    before do
      @sexp = Sexp.new([:if, [:abc, 2, 3], [:def, 4, 5], nil])
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
        Sexp.new([[:abc], 2, 3, [:def, 3, 4]]).children.should == [[:abc], 2, 3, [:def, 3, 4]]
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
          @old_annotations, Sexp.annotations = Sexp.annotations, [annotator_1, annotator_2]
        end
        
        after do
          Sexp.annotations = @old_annotations
        end
        
        it 'runs the annotators in order' do
          x = Object.new
          def x.name; "x"; end
          result = Sexp.new([x])
          x.weird_thing!.should == "silly!"
          x.weird_thing_2!.should == "world"
        end
      end
      
      context '#eval_as_constant' do
        it 'converts :var_ref constants' do
          result = mock
          scope = Scope.new(nil, nil, {'B' => result})
          sexp = Sexp.new([:var_ref, [:@const, 'B', [1, 17]]])
          sexp.eval_as_constant(scope).should == result
        end

        it 'converts :const_ref constants' do
          result = mock
          scope = Scope.new(nil, nil, {'C' => result})
          sexp = Sexp.new([:const_ref, [:@const, 'C', [4, 17]]])
          sexp.eval_as_constant(scope).should == result
        end
        
        it 'converts :top_const_ref constants' do
          result = mock
          Scope::GlobalScope.constants['__testing_ref__'] = result
          sexp = Sexp.new([:top_const_ref, [:@const, '__testing_ref__', [4, 17]]])
          sexp.eval_as_constant(nil).should == result
        end
        
        it 'converts :const_path_ref constants' do
          input = [:const_path_ref, [:const_path_ref, [:const_path_ref, [:const_path_ref,
                   [:var_ref, [:@const, "B", [1, 7]]], [:@const, "M", [1, 10]]],
                   [:@const, "C", [1, 13]]], [:@const, "D", [1, 16]]], [:@const, "E", [1, 19]]]
          global, b_sym, m_sym, c_sym, d_sym, e_sym = mock, mock, mock, mock, mock, mock
          b_scope, m_scope, c_scope, d_scope = mock, mock, mock, mock
          global.should_receive(:constants).and_return({'B' => b_sym})
          b_sym.should_receive(:scope).and_return(b_scope)
          b_scope.should_receive(:constants).and_return({'M' => m_sym})
          m_sym.should_receive(:scope).and_return(m_scope)
          m_scope.should_receive(:constants).and_return({'C' => c_sym})
          c_sym.should_receive(:scope).and_return(c_scope)
          c_scope.should_receive(:constants).and_return({'D' => d_sym})
          d_sym.should_receive(:scope).and_return(d_scope)
          d_scope.should_receive(:constants).and_return({'E' => e_sym})
          sexp = Sexp.new(input)
          sexp.eval_as_constant(global).should == e_sym
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