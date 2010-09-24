# This warning is used when
class Wool::MisalignedUnindentationWarning < Wool::LineWarning
  type :style
  severity 2
  short_desc 'Misaligned Unindentation'
  desc { "Expected #{@expectation} spaces, but instead found #{get_indent.size}" }

  def initialize(file, line, expectation, settings={})
    super(file, line, settings)
    @expectation = expectation
  end

  def fix(context_stack = nil)
    indent self.line, @expectation
  end
  
end