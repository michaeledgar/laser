# Warning for not putting space around operators
class Wool::OperatorSpacing < Wool::Warning
  OPERATORS = %w(+ - / * != !== = == === ~= !~ += -= *= /= ** **= ||= || && &&= &= |= | & ^)

  def self.matches_operator?(line, op)
    embed = op.gsub(/(\+|\-|\*|\||\^)/, '\\\\\\1')
    op if line =~ /([A-Za-z0-9_]!|[A-Za-z0-9_?])#{embed}/ || line =~ /(#{embed})[$A-Za-z0-9_?!]/
  end
  def self.matching_operator(line)
    OPERATORS.each do |op|
      return op if matches_operator?(line, op)
    end
    nil
  end
  
  def self.match?(line, context_stack)
    !!self.matching_operator(line)
  end
  
  def initialize(file, line)
    super("No operator spacing", file, line, 0, 5)
  end
  
  def fix(context_stack)
    line = self.line.dup
    OPERATORS.each do |op|
      next if op == '==' && line =~ /!==/
      next if op == '=' && line =~ /!=/
      embed = op.gsub(/(\+|\-|\*|\||\^)/, '\\\\\\1')
      line.gsub!(/([A-Za-z0-9_]!|[A-Za-z0-9_?])(#{embed})/, '\1 \2')
      line.gsub!(/(#{embed})([$A-Za-z0-9_?!])/, '\1 \2')
    end
    line
  end
  
  def desc
    first_operator = self.class.matching_operator(@line)
    "Insufficient spacing around #{first_operator}"
  end
end