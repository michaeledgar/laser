require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe RescueExceptionWarning do
  it 'is a file-based warning' do
    RescueExceptionWarning.new('(stdin)', 'hello').should be_a(FileWarning)
  end

  it 'matches against a rescue of Exception as the only type' do
    RescueExceptionWarning.should warn('begin; puts x; rescue Exception; end')
  end
  
  it 'does not match when a rescue of StandardError is used' do
    RescueExceptionWarning.should_not warn('begin; puts x; rescue StandardError; end')
  end
  
  it 'matches against a rescue of Exception with an additional identifier' do
    RescueExceptionWarning.should warn('begin; puts x; rescue Exception => e; end')
  end
  
  it 'does not match when a rescue of StandardError is used with an additional identifier' do
    RescueExceptionWarning.should_not warn('begin; puts x; rescue StandardError => e; end')
  end
  
  it 'matches against a rescue of Exception that is specified second' do
    RescueExceptionWarning.should warn('begin; puts x; rescue StandardError, Exception; end')
  end
  
  it 'does not match when a rescue of StandardError is specified second' do
    RescueExceptionWarning.should_not warn('begin; puts x; rescue StandardError, StandardError; end')
  end
  
  it 'matches against a rescue of Exception that is specified second w/ addl identifier' do
    RescueExceptionWarning.should warn('begin; puts x; rescue StandardError, Exception => err; end')
  end
  
  it 'does not match when a rescue of StandardError is specified second w/ addl identifier' do
    RescueExceptionWarning.should_not warn('begin; puts x; rescue StandardError, StandardError => err; end')
  end

  describe '#fix' do
    it 'fixes a rescue of Exception as the only type' do
      input = <<-EOF
begin
  puts x
rescue Exception  # bad
end
EOF
      output = <<-EOF
begin
  puts x
rescue StandardError  # bad
end
EOF
      RescueExceptionWarning.new('(stdin)', input).match?(input).first.fix.should == output
    end
    
    it 'fixes a rescue of Exception with an additional identifier' do
      input = <<-EOF
begin
  puts x
rescue Exception => e  # bad
end
EOF
      output = <<-EOF
begin
  puts x
rescue StandardError => e  # bad
end
EOF
      RescueExceptionWarning.new('(stdin)', input).match?(input).first.fix.should == output
    end
    
    it 'fixes a rescue of Exception that is specified second' do
      input = <<-EOF
begin
  puts x
rescue StandardError, Exception  # bad
end
EOF
      output = <<-EOF
begin
  puts x
rescue StandardError, StandardError  # bad
end
EOF
      RescueExceptionWarning.new('(stdin)', input).match?(input).first.fix.should == output
    end
    
    it 'fixes a rescue of Exception that is specified second w/ addl identifier' do
      input = <<-EOF
begin
  puts x
rescue StandardError, Exception => e  # bad
end
EOF
      output = <<-EOF
begin
  puts x
rescue StandardError, StandardError => e  # bad
end
EOF
      RescueExceptionWarning.new('(stdin)', input).match?(input).first.fix.should == output
    end
  end
end