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
    self.line
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