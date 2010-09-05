class Wool::GenericLineLengthWarning < Wool::Warning
  def self.line_length_limit
    @line_length_limit ||= 80000
  end
  def self.line_length_limit=(val)
    @line_length_limit = val
  end
  class << self
    attr_accessor :severity
  end

  def self.matches(line, context)
    line.size >= self.line_length_limit
  end
  
  def initialize(file, line)
    super('Line too long', file, line, 0, self.severity)
  end
end

module Wool
  def LineLengthCustomSeverity(size, severity)
    new_warning = Class.new(Wool::GenericLineLengthWarning)
    new_warning.line_length_limit = size
    new_warning.severity = severity
  end
  
  def self.LineLengthMaximum(size)
    LineLengthCustomSeverity(size, 8)
  end
  p Wool.methods
  def self.LineLengthWarning(size)
    LineLengthCustomSeverity(size, 3)
  end
  module_function :LineLengthMaximum, :LineLengthWarning
end