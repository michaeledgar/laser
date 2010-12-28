  # Warning for using semicolons outside of class declarations.
class Wool::ExtraBlankLinesWarning < Wool::FileWarning
  EXTRA_LINE = /\n[\t ]*\Z/
  type :style
  severity 1
  short_desc 'Extra blank lines'
  desc { "This file has #{count_extra_lines} blank lines at the end of it." }

  def match?(body = self.body)
    body =~ EXTRA_LINE
  end

  def fix(body = self.body)
    body.gsub(/\s*\Z/, '')
  end

  # Counts how many extra lines there are at the end of the file.
  def count_extra_lines
    # We use this logic because #lines ignores blank lines at the end, and
    # split(/\n/) does as well.
    count = 0
    working_body = self.body.dup
    while working_body =~ EXTRA_LINE
      working_body.sub!(EXTRA_LINE, '')
      count += 1
    end
    count
  end
end