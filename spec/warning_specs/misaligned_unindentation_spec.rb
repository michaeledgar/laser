require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wool::MisalignedUnindentationWarning do
  context 'when fixing' do
    before do
      @warning = Wool::MisalignedUnindentationWarning.new('(stdin)', '   a + b', 2)
      @other_warning = Wool::MisalignedUnindentationWarning.new('(stdin)', ' a + b', 2)
      @warning_3 = Wool::MisalignedUnindentationWarning.new('(stdin)', 'a + b', 4)
    end
    
    it 'fixes by removing more spaces than expected' do
      @warning.fix(nil).should == '  a + b'
    end
    
    it 'fixes by adding a second space' do
      @other_warning.fix(nil).should == '  a + b'
    end
    
    it 'fixes by adding indentation' do
      @warning_3.fix(nil).should == '    a + b'
    end
  end
end
