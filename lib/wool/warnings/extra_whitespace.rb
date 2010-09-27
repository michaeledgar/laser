# Warning for having extra space at the end of a line.
class Wool::ExtraWhitespaceWarning < Wool::LineWarning
  type :style
  severity 2
  short_desc 'Extra Whitespace'
  desc 'The line has trailing whitespace.'

  def match?(body = self.body)
    /\s+$/ === line
  end

  def fix
    self.line.gsub(/\s+$/, '')
  end
end