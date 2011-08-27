require_relative 'spec_helper'

describe Frequency do
  describe Frequency::NEVER do
    it { Frequency::NEVER.should be == Frequency::NEVER }
    it { Frequency::NEVER.should be < Frequency::MAYBE  }
    it { Frequency::NEVER.should be < Frequency::ALWAYS }
  end
  
  describe Frequency::MAYBE do
    it { Frequency::MAYBE.should be > Frequency::NEVER  }
    it { Frequency::MAYBE.should be == Frequency::MAYBE }
    it { Frequency::MAYBE.should be < Frequency::ALWAYS }
  end
  
  describe Frequency::ALWAYS do
    it { Frequency::ALWAYS.should be > Frequency::NEVER   }
    it { Frequency::ALWAYS.should be > Frequency::MAYBE   }
    it { Frequency::ALWAYS.should be == Frequency::ALWAYS }
  end
  
  it { Frequency.should_not respond_to(:new) }
end
