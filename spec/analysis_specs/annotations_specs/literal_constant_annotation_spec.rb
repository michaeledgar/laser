require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe LiteralConstantAnnotation do
  extend AnalysisHelpers
  clean_registry
  
  it_should_behave_like 'an annotator'
  
  it 'adds the #class_estimate method to Sexp' do
    Sexp.instance_methods.should include(:is_constant)
    Sexp.instance_methods.should include(:constant_value)
  end
  
  it 'defaults to assigning is_constant=false, constant_value=:none' do
    tree = Sexp.new(Ripper.sexp('a'))
    LiteralConstantAnnotation.new.annotate!(tree)
    list = tree[1]
    list[0][1].is_constant.should be false
    list[0][1].constant_value.should be :none
  end
  
  describe 'character literals' do
    it 'works with single-char literals' do
      tree = Sexp.new(Ripper.sexp('a = ?X'))
      LiteralConstantAnnotation.new.annotate!(tree)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == 'X'
    end
    
    it 'works with oddball char literals' do
      tree = Sexp.new(Ripper.sexp('a = ?\M-\C-a'))
      LiteralConstantAnnotation.new.annotate!(tree)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == "\x81"
    end
  end
  
  describe 'handling string literals' do
    it 'should interpret simple strings' do
      input = 'a = "abc def"'
      tree = Sexp.new(Ripper.sexp(input))
      ParentAnnotation.new.annotate_with_text(tree, input)
      SourceLocationAnnotation.new.annotate_with_text(tree, input)
      LiteralConstantAnnotation.new.annotate_with_text(tree, input)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == "abc def"
    end
    
    it 'should give up with complex interpolation' do
      input = 'a = "abc #{foobar()} def"'
      tree = Sexp.new(Ripper.sexp(input))
      ParentAnnotation.new.annotate_with_text(tree, input)
      SourceLocationAnnotation.new.annotate_with_text(tree, input)
      LiteralConstantAnnotation.new.annotate_with_text(tree, input)
      list = tree[1]
      list[0][2].is_constant.should be false
    end
    
    it 'should handle embedded escapes' do
      input = 'a = "abc \n \x12def"'
      tree = Sexp.new(Ripper.sexp(input))
      ParentAnnotation.new.annotate_with_text(tree, input)
      SourceLocationAnnotation.new.annotate_with_text(tree, input)
      LiteralConstantAnnotation.new.annotate_with_text(tree, input)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == "abc \n \x12def"
    end
    
    it 'should not evaluate embedded escapes for single-quoted strings' do
      input = %q{a = 'abc \n \x12def'}
      tree = Sexp.new(Ripper.sexp(input))
      ParentAnnotation.new.annotate_with_text(tree, input)
      SourceLocationAnnotation.new.annotate_with_text(tree, input)
      LiteralConstantAnnotation.new.annotate_with_text(tree, input)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == 'abc \n \x12def'
    end
  end
  
  describe 'handling integer literals' do
    it 'discovers the constant value for small decimal literals' do
      tree = Sexp.new(Ripper.sexp('a = 5'))
      LiteralConstantAnnotation.new.annotate!(tree)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == 5
    end
    
    it 'discovers the constant value for huge integer literals' do
      tree = Sexp.new(Ripper.sexp('a = 5123907821349078'))
      LiteralConstantAnnotation.new.annotate!(tree)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == 5123907821349078
    end
    
    it 'discovers the constant value for hex integer literals' do
      tree = Sexp.new(Ripper.sexp('a = 0xabde3456'))
      LiteralConstantAnnotation.new.annotate!(tree)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == 0xabde3456
    end
    
    it 'discovers the constant value for octal integer literals' do
      tree = Sexp.new(Ripper.sexp('a = 012343222245566'))
      LiteralConstantAnnotation.new.annotate!(tree)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == 012343222245566
    end
    
    it 'discovers the constant value for binary integer literals' do
      tree = Sexp.new(Ripper.sexp('a = 0b10100011101010110001'))
      LiteralConstantAnnotation.new.annotate!(tree)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == 0b10100011101010110001
    end
  end
  
  describe 'handling float literals' do
    it 'discovers the constant value for small decimal literals' do
      tree = Sexp.new(Ripper.sexp('a = 5.124897e3'))
      LiteralConstantAnnotation.new.annotate!(tree)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == 5.124897e3
    end
  end
  
  describe 'symbol literals' do
    [:abc_def, :ABC_DEF, :@abc_def, :$abc_def, :@@abc_def, :"hello-world"].each do |sym|
      it "should convert simple symbols of the form #{sym.inspect}" do
        input = "a = #{sym.inspect}"
        tree = Sexp.new(Ripper.sexp(input))
        ParentAnnotation.new.annotate_with_text(tree, input)
        SourceLocationAnnotation.new.annotate_with_text(tree, input)
        LiteralConstantAnnotation.new.annotate_with_text(tree, input)
        list = tree[1]
        list[0][2].is_constant.should be true
        list[0][2].constant_value.should == sym
      end
    end

    # [:program,
    #  [[:hash,
    #    [:assoclist_from_args,
    #     [[:assoc_new,
    #       [:@label, "abc:", [1, 1]],
    #       [:symbol_literal, [:symbol, [:@kw, "def", [1, 7]]]]]]]]]]
    it 'can discover the value of labels in 1.9 hash syntax' do
      input = '{abc: :def}'
      tree = Sexp.new(Ripper.sexp(input))
      LiteralConstantAnnotation.new.annotate_with_text(tree, input)
      label = tree[1][0][1][1][0][1]
      label.is_constant.should be true
      label.constant_value.should == :abc
    end
  end
  
  describe 'inclusive range literals' do
    it 'calculates a constant if both ends of the range are constants' do
      tree = Sexp.new(Ripper.sexp('a = 2..0x33'))
      LiteralConstantAnnotation.new.annotate!(tree)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == (2..51)
    end
    
    it 'does not create a constant if one of the ends is not a constant' do
      tree = Sexp.new(Ripper.sexp('a = 2..(foobar(2))'))
      LiteralConstantAnnotation.new.annotate!(tree)
      list = tree[1]
      list[0][2].is_constant.should be false
    end
  end
  
  describe 'exclusive range literals' do
    it 'calculates a constant if both ends of the range are constants' do
      tree = Sexp.new(Ripper.sexp('a = 2...0x33'))
      LiteralConstantAnnotation.new.annotate!(tree)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == (2...51)
    end
    
    it 'does not create a constant if one of the ends is not a constant' do
      tree = Sexp.new(Ripper.sexp('a = 2...(foobar(2))'))
      LiteralConstantAnnotation.new.annotate!(tree)
      list = tree[1]
      list[0][2].is_constant.should be false
    end
  end
  
  describe 'regex literals' do
    it 'interprets a simple constant regex with standard syntax' do
      input = 'a = /abcdef/'
      tree = Sexp.new(Ripper.sexp(input))
      ParentAnnotation.new.annotate_with_text(tree, input)
      SourceLocationAnnotation.new.annotate_with_text(tree, input)
      LiteralConstantAnnotation.new.annotate_with_text(tree, input)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == /abcdef/
    end
    
    it 'does not try to fold complex interpolated regexps' do
      input = 'a = /abc#{abc()}def/'
      tree = Sexp.new(Ripper.sexp(input))
      ParentAnnotation.new.annotate_with_text(tree, input)
      SourceLocationAnnotation.new.annotate_with_text(tree, input)
      LiteralConstantAnnotation.new.annotate_with_text(tree, input)
      list = tree[1]
      list[0][2].is_constant.should be false
    end

    it 'interprets a simple regex with nonstandard syntax and options' do
      input = 'a = %r|abcdef|im'
      tree = Sexp.new(Ripper.sexp(input))
      ParentAnnotation.new.annotate_with_text(tree, input)
      SourceLocationAnnotation.new.annotate_with_text(tree, input)
      LiteralConstantAnnotation.new.annotate_with_text(tree, input)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == /abcdef/im
    end
    
    it 'interprets a simple regex with extended mode' do
      input = 'a = %r|abcdef|x'
      tree = Sexp.new(Ripper.sexp(input))
      ParentAnnotation.new.annotate_with_text(tree, input)
      SourceLocationAnnotation.new.annotate_with_text(tree, input)
      LiteralConstantAnnotation.new.annotate_with_text(tree, input)
      list = tree[1]
      list[0][2].is_constant.should be true
      list[0][2].constant_value.should == /abcdef/x
    end
  end
end