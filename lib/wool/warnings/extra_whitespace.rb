# Warning for having extra space at the end of a line.
class Wool::ExtraWhitespaceWarning < Wool::LineWarning
  type :style
  severity 2
  short_desc 'Extra Whitespace'
  desc 'The line has trailing whitespace.'

  def match?(body = self.body, context_stack = nil, settings = {})
    /\s+$/ === line
  end

  def fix(context_stack = nil)
    self.line.gsub(/\s+$/, '')
  end
end