# Warning for having extra space at the end of a line.
class Wool::ExtraWhitespaceWarning < Wool::LineWarning
  def self.match?(line, context_stack, settings = {})
    /\s+$/ === line
  end

  def initialize(file, line)
    super('Extra Whitespace', file, line, 0, 2)
  end

  def desc
    'The line has trailing whitespace.'
  end

  def fix(context_stack = nil)
    self.line.gsub(/\s+$/, '')
  end
end
