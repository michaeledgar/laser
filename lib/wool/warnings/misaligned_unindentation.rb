# This warning is used when
class Wool::MisalignedUnindentationWarning < Wool::LineWarning
  self.short_name = 'S004'
  def match?(body = self.body, context_stack = nil, settings = {})
    false
  end

  def initialize(file, line, expectation, settings={})
    super('Misaligned Unindentation', file, line, 0, 2)
    @settings = settings
    @expectation = expectation
  end

  def fix(context_stack = nil)
    indent self.line, @expectation
  end

  def desc
    actual = line.match(/^\s*/)[0].size
    "Expected #{@expectation} spaces, but instead found #{actual}"
  end
end