# This warning is used when
class Wool::MisalignedUnindentationWarning < Wool::LineWarning
  type :style
  severity 2
  short_desc 'Misaligned Unindentation'

  def initialize(file, line, expectation, settings={})
    super(file, line, settings)
    @expectation = expectation
  end

  def match?(body = self.body, context_stack = nil, settings = {})
    false
  end

  def fix(context_stack = nil)
    indent self.line, @expectation
  end

  def desc
    actual = line.match(/^\s*/)[0].size
    "Expected #{@expectation} spaces, but instead found #{actual}"
  end
end