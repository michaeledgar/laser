class Wool::GenericLineLengthWarning < Wool::LineWarning
  def self.line_length_limit
    @line_length_limit ||= 80000
  end
  def self.line_length_limit=(val)
    @line_length_limit = val
  end
  class << self
    attr_accessor :severity
  end

  def self.match?(line, context, settings = {})
    !!(line.size > self.line_length_limit)
  end

  def initialize(file, line)
    super('Line too long', file, line, 0, self.class.severity)
  end

  def fix(content_stack = nil)
    result = fix_long_comment(self.line)
    return result if result
    self.line
  end

  def fix_long_comment(text)
    # Must have no leading text
    return text unless text =~ /^(\s+)\#\s*(.*)\Z/
    indent, comment = $1.size, $2
    # The "+ 2" is (indent)#(single space)
    space_for_text_per_line = self.class.line_length_limit - (indent.size + 2)
    lines = ['']
    words = comment.split(/\s/)
    quota = space_for_text_per_line
    current_line = 0
    while words.any?
      word = words.shift
      # break on word big enough to make a new line, unless its the first word
      if quota - (word.size + 1) < 0 && quota < space_for_text_per_line
        current_line += 1
        lines << ''
      end
      lines[current_line] << ' ' if lines[current_line].any?
      lines[current_line] << word
    end
    lines.map { |line| " " * indent + '# ' + line }.join("\n")
  end

  def desc
    "Line length: #{line.size} > #{self.class.line_length_limit} (max)"
  end
end

module Wool
  def LineLengthCustomSeverity(size, severity)
    new_warning = Class.new(Wool::GenericLineLengthWarning)
    new_warning.line_length_limit = size
    new_warning.severity = severity
    new_warning
  end

  def LineLengthMaximum(size)
    LineLengthCustomSeverity(size, 8)
  end

  def LineLengthWarning(size)
    LineLengthCustomSeverity(size, 3)
  end
  module_function :LineLengthMaximum, :LineLengthWarning, :LineLengthCustomSeverity
end