require_relative 'spec_helper'

describe MisalignedUnindentationWarning do
  describe 'when fixing' do
    it 'is a line-based warning' do
      MisalignedUnindentationWarning.new('(stdin)', 'hello', 80).should be_a(LineWarning)
    end

    it 'matches nothing' do
      MisalignedUnindentationWarning.should_not warn(' a + b', 2)
    end

    it 'fixes by removing more spaces than expected' do
      MisalignedUnindentationWarning.should correct_to('   a + b', '  a + b', 2)
    end

    it 'fixes by adding a second space' do
      MisalignedUnindentationWarning.should correct_to(' a + b', '  a + b', 2)
    end

    it 'fixes by adding indentation' do
      MisalignedUnindentationWarning.should correct_to('a + b', '    a + b', 4)
    end

    it 'describes the incorrect indentation values' do
      warning = MisalignedUnindentationWarning.new('(stdin)', '   a + b', 2)
      other_warning = MisalignedUnindentationWarning.new('(stdin)', ' a + b', 2)
      warning_3 = MisalignedUnindentationWarning.new('(stdin)', 'a + b', 4)
      warning.desc.should =~ /Expected 2/
      warning.desc.should =~ /found 3/
      other_warning.desc.should =~ /Expected 2/
      other_warning.desc.should =~ /found 1/
    end
  end
end
