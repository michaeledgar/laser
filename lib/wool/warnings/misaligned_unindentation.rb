# This warning is used when
class Wool::MisalignedUnindentationWarning < Wool::LineWarning
  def self.match?(line, context_stack, settings = {})
    false
  end

  def initialize(file, line, expectation, settings={})
    super('Misaligned Unindentation', file, line, 0, 2)
    @expectation = expectation
  end

  def fix(context_stack = nil)
    ' ' * @expectation + self.line.lstrip
  end

  def desc
    actual = line.match(/^\s*/)[0].size
    "Expected #{@expectation} spaces, but instead found #{actual}"
  end
end