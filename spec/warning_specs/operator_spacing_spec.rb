require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::OperatorSpacing do
  Wool::OperatorSpacing::OPERATORS.each do |operator|
    context "with #{operator}" do
      it "matches when there is no space on the left side" do
        Wool::OperatorSpacing.match?("a#{operator} b", nil).should be_true
      end
      
      it "matches when there is no space on the right side" do
        Wool::OperatorSpacing.match?("a #{operator}b", nil).should be_true
      end
      
      it "matches when there is no space on both sides" do
        Wool::OperatorSpacing.match?("a#{operator}b", nil).should be_true
      end
      
      it "doesn't match when there is exactly one space on both sides" do
        Wool::OperatorSpacing.match?("a #{operator} b", nil).should be_false
      end
      
      context 'when fixing' do
        before do
          @warning_1 = Wool::OperatorSpacing.new('(stdin)', "a #{operator} b")
          @warning_2 = Wool::OperatorSpacing.new('(stdin)', "a#{operator} b")
          @warning_3 = Wool::OperatorSpacing.new('(stdin)', "a #{operator}b")
          @warning_4 = Wool::OperatorSpacing.new('(stdin)', "a#{operator}b")
        end

        it 'changes nothing when there is one space on both sides' do
          @warning_1.fix(nil).should == "a #{operator} b"
        end

        it 'fixes by inserting an extra space on the left' do
          @warning_2.fix(nil).should == "a #{operator} b"
        end
        
        it 'fixes by inserting an extra space on the right' do
          @warning_3.fix(nil).should == "a #{operator} b"
        end
        
        it 'fixes by inserting an extra space on both sides' do
          @warning_4.fix(nil).should == "a #{operator} b"
        end
      end
    end
  end
end
