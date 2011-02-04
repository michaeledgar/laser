require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SexpAnalysis::SingleLHSExpression do
  describe '#name' do
    it 'extracts the name from the identifier wrapped by the SingleLHSExpression' do
      tree = Sexp.new([:var_field, [:@ident, "a", [1, 0]]])
      ExpandedIdentifierAnnotation.new.annotate!(tree)
      SingleLHSExpression.new(tree).names.should == ['a']
    end
  end
  
  describe '#assignment_pairs' do
    it 'should simply pair the given values to the LHS node' do
      tree = Sexp.new([:var_field, [:@ident, "$b", [1, 0]]])
      ExpandedIdentifierAnnotation.new.annotate!(tree)
      SingleLHSExpression.new(tree).assignment_pairs(4).should == [[tree, 4]]
      SingleLHSExpression.new(tree).assignment_pairs([1, 2]).should == [[tree, [1, 2]]]
    end
  end
end

describe SexpAnalysis::MultipleLHSExpression do
  describe '#name' do
    it 'extracts the names from a simple set of expressions' do
      input = 'a, b, c, d = nil'
      tree = Sexp.new(Ripper.sexp(input))[1][0][1]
      ExpandedIdentifierAnnotation.new.annotate!(tree)
      MultipleLHSExpression.new(tree).names.should == ['a', 'b', 'c', 'd']
    end
    it 'extracts all the names from the subexpressions' do
      input = 'a, (Z, ((b, $f, j), (i, p)), *d, e), *k, $l = nil'
      tree = Sexp.new(Ripper.sexp(input))[1][0][1]
      ExpandedIdentifierAnnotation.new.annotate!(tree)
      MultipleLHSExpression.new(tree).names.should == ['a', 'Z', 'b', '$f', 'j', 'i', 'p', 'd', 'e', 'k', '$l']
    end
  end
  
  describe '#assignment_pairs' do
    it 'should pair off each constituent element with a value' do
      outputs = Annotations.annotate_inputs(
          [['(stdin)', 'a, b, c, d = 1, 2, [3, 4]']])
      lhs = MultipleLHSExpression.new(outputs[0][1][1][0][1])
      rhs = MultipleRHSExpression.new(outputs[0][1][1][0][2])
      lvals = outputs[0][1][1][0][1]
      lhs.assignment_pairs(rhs.constant_values).should ==
          [[lvals[0], 1], [lvals[1], 2], [lvals[2], [3, 4]], [lvals[3], nil]]
    end
    
    it 'should pair off each constituent element with a value with subassignment' do
      outputs = Annotations.annotate_inputs(
          [['(stdin)', 'a, b, (c, d) = 1, 2, [3, 4]']])
      lhs = MultipleLHSExpression.new(outputs[0][1][1][0][1])
      rhs = MultipleRHSExpression.new(outputs[0][1][1][0][2])
      lvals = outputs[0][1][1][0][1]
      lhs.assignment_pairs(rhs.constant_values).should ==
          [[lvals[0], 1], [lvals[1], 2], [lvals[2][1][0], 3], [lvals[2][1][1], 4]]
    end
    
    it 'can pair off with nested subassignment' do
      outputs = Annotations.annotate_inputs(
          [['(stdin)', 'a, b, (c, (d, f), g), e = 1, 2, [[9, 8], [3, 4], 5], 6']])
      lhs = MultipleLHSExpression.new(outputs[0][1][1][0][1])
      rhs = MultipleRHSExpression.new(outputs[0][1][1][0][2])
      lvals = outputs[0][1][1][0][1]
      lhs.assignment_pairs(rhs.constant_values).should ==
          [[lvals[0], 1], [lvals[1], 2], [lvals[2][1][0], [9, 8]],
           [lvals[2][1][1][1][0], 3], [lvals[2][1][1][1][1], 4], [lvals[2][1][2], 5],
           [lvals[3], 6]]
    end
    
    it 'works with unmet splats and no subassignments' do
      outputs = Annotations.annotate_inputs(
          [['(stdin)', 'a, *b, c, d = 1, 2, [3, 4]']])
      lhs = MultipleLHSExpression.new(outputs[0][1][1][0][1])
      rhs = MultipleRHSExpression.new(outputs[0][1][1][0][2])
      lvals = outputs[0][1][1][0][1]
      lhs.assignment_pairs(rhs.constant_values).should ==
          [[lvals[1][0], 1], [lvals[2], []], [lvals[3][0], 2], [lvals[3][1], [3, 4]]]
    end
    
    it 'works with met splats and no subassignments' do
      outputs = Annotations.annotate_inputs(
          [['(stdin)', 'a, *b, c, d = 1, 2, 3, 4, 5, 6, [3, 4]']])
      lhs = MultipleLHSExpression.new(outputs[0][1][1][0][1])
      rhs = MultipleRHSExpression.new(outputs[0][1][1][0][2])
      lvals = outputs[0][1][1][0][1]
      lhs.assignment_pairs(rhs.constant_values).should ==
          [[lvals[1][0], 1], [lvals[2], [2, 3, 4, 5]], [lvals[3][0], 6], [lvals[3][1], [3, 4]]]
    end
    
    it 'works with nested splats and subassignments' do
      outputs = Annotations.annotate_inputs(
          [['(stdin)', 'a, *b, (c, *d, e) = 1, 2, 3, [4, 5, 6, 3, 4]']])
      lhs = MultipleLHSExpression.new(outputs[0][1][1][0][1])
      rhs = MultipleRHSExpression.new(outputs[0][1][1][0][2])
      lvals = outputs[0][1][1][0][1]
      lhs.assignment_pairs(rhs.constant_values).should ==
          [[lvals[1][0], 1], [lvals[2], [2, 3]], [lvals[3][0][1][1][0], 4],
           [lvals[3][0][1][2], [5, 6, 3]], [lvals[3][0][1][3][0], 4]]
    end
  end
end

describe SexpAnalysis::SingleRHSExpression do
  before do
    outputs = Annotations.annotate_inputs([['(stdin)', 'a = 123'], ['(stdin)', 'a = foobar()']])
    @const_rhs = SingleRHSExpression.new(outputs[0][1][1][0][2])
    @var_rhs = SingleRHSExpression.new(outputs[1][1][1][0][2])
  end
  describe '#constant_size?' do
    it 'is true' do
      @const_rhs.constant_size?.should be true
      @var_rhs.constant_size?.should be true
    end
  end
  describe '#size' do
    it 'is 1' do
      @const_rhs.size.should == 1
      @var_rhs.size.should == 1
    end
  end
  
  describe '#is_constant' do
    it 'is true iff the RHS node is constant' do
      @const_rhs.is_constant.should be true
      @var_rhs.is_constant.should be false
    end
  end
  
  describe '#constant_values' do
    it 'is the only nodes constant value if it is constant' do
      @const_rhs.constant_values.should == [123]
    end
  end
end

describe SexpAnalysis::StarRHSExpression do
  before do
    outputs = Annotations.annotate_inputs([['(stdin)', 'a = *123'], ['(stdin)', 'a = *1..3'], ['(stdin)', 'a = *foobar()']])
    @const_rhs = StarRHSExpression.new(outputs[0][1][1][0][2][2])
    @range_rhs = StarRHSExpression.new(outputs[1][1][1][0][2][2])
    @var_rhs = StarRHSExpression.new(outputs[2][1][1][0][2][2])
  end
  describe '#constant_size?' do
    it 'is true if the splatted value is a constant' do
      @const_rhs.constant_size?.should be true
      @range_rhs.constant_size?.should be true
    end
    it 'is false if the splatten value is variable' do
      @var_rhs.constant_size?.should be false
    end
  end
  describe '#size' do
    it 'is the size of the splatted constant' do
      @const_rhs.size.should == 1
      @range_rhs.size.should == 3
    end
  end
  
  describe '#is_constant' do
    it 'is true iff the RHS node is constant' do
      @const_rhs.is_constant.should be true
      @range_rhs.is_constant.should be true
      @var_rhs.is_constant.should be false
    end
  end
  
  describe '#constant_values' do
    it "is the node's constant value, splatted, if it is constant" do
      @const_rhs.constant_values.should == [123]
      @range_rhs.constant_values.should == [1, 2, 3]
    end
  end
end


describe SexpAnalysis::MultipleRHSExpression do
  before do
    outputs = Annotations.annotate_inputs(
        [['(stdin)', 'a = 1, 2, [3, 4], *123, "hi"'],
         ['(stdin)', 'a = 1, *(1...4), 2, [3, 4], *123, "hi"'],
         ['(stdin)', 'a = 2, 4.44, foobar(), [3, 4]'],
         ['(stdin)', 'a = 2, 4.44, *foobar(), [3, 4]']])
    @const_rhs = MultipleRHSExpression.new(outputs[0][1][1][0][2])
    @bigger_rhs = MultipleRHSExpression.new(outputs[1][1][1][0][2])
    @var_rhs = MultipleRHSExpression.new(outputs[2][1][1][0][2])
    @very_var_rhs = MultipleRHSExpression.new(outputs[3][1][1][0][2])
  end
  describe '#constant_size?' do
    it 'is true if the rhs contains no variable splats' do
      @const_rhs.constant_size?.should be true
      @bigger_rhs.constant_size?.should be true
      @var_rhs.constant_size?.should be true
    end
    it 'is false if the rhs contains a variable splat' do
      @very_var_rhs.constant_size?.should be false
    end
  end
  describe '#size' do
    it 'is the number of elements with expanded splats' do
      @const_rhs.size.should == 5
      @bigger_rhs.size.should == 8
      @var_rhs.size.should == 4
    end
  end
  
  describe '#is_constant' do
    it 'is true iff the RHS node is constant' do
      @const_rhs.is_constant.should be true
      @bigger_rhs.is_constant.should be true
      @var_rhs.is_constant.should be false
      @very_var_rhs.is_constant.should be false
    end
  end
  # 
  describe '#constant_values' do
    it "is the node's constant value, splatted, if it is constant" do
      @const_rhs.constant_values.should == [1, 2, [3, 4], 123, "hi"]
      @bigger_rhs.constant_values.should == [1, 1, 2, 3, 2, [3, 4], 123, "hi"]
    end
  end
end