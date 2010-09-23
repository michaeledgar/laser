# Warning for having extra space at the end of a line.
class Wool::ExtraWhitespaceWarning < Wool::LineWarning
  type :style
  
  def initialize(file, line, settings={})
    super('Extra Whitespace', file, line, 0, 2)
  end

  def desc
    'The line has trailing whitespace.'
  end

  def match?(body = self.body, context_stack = nil, settings = {})
    /\s+$/ === line
  end

  def fix(context_stack = nil)
    self.line.gsub(/\s+$/, '')
  end
end