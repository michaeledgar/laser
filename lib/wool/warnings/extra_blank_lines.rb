# Warning for using semicolons outside of class declarations.
class Wool::ExtraBlankLinesWarning < Wool::FileWarning
  EXTRA_LINE = /\n[\t ]*\Z/
  def self.match?(file, context_stack, settings = {})
    file =~ EXTRA_LINE
  end
  
  def initialize(file, body)
    super('Extra blank lines', file, body, 0, severity)
  end
  
  def desc
    "This file has #{count_extra_lines} blank lines at the end of it."
  end
  
  def fix(context_stack = nil)
    body = self.body.dup
    while body =~ EXTRA_LINE
      body.gsub!(EXTRA_LINE, '')
    end
    body
  end
  
  def count_extra_lines
    count = 0
    working_body = self.body.dup
    while working_body =~ EXTRA_LINE
      working_body.sub!(EXTRA_LINE, '')
      count += 1
    end
    count
  end
end