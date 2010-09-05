# This warning is used when 
class Wool::MisalignedUnindentationWarning < Wool::Warning
  def self.match?(line, context_stack)
    false
  end
  
  def initialize(file, line, expectation)
    super('Misaligned Unindentation', file, line, 0, 2)
    @expectation = expectation
  end
  
  def fix(context_stack)
    ' ' * @expectation + self.line.lstrip
  end
  
  def desc
    actual = line.match(/^\s*/)[0].size
    "Expected #{@expectation} spaces, but instead found #{actual}"
  end
end