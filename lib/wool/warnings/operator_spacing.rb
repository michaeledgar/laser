# Warning for not putting space around operators
class Wool::OperatorSpacing < Wool::LineWarning
  OPERATORS = %w(+ - / * != !== = == === ~= !~ += -= *= /= ** **= ||= || && &&= &= |= | & ^)

  def self.matches_operator?(line, op)
    return false if line =~ /^\s*def /
    return false if op == '|' && is_block_line?(line)
    embed = op.gsub(/(\+|\-|\*|\||\^)/, '\\\\\\1')
    op if line =~ /([A-Za-z0-9_]!|[A-Za-z0-9_?])#{embed}/ || line =~ /(#{embed})[$A-Za-z0-9_?!]/
  end
  
  def self.matching_operator(line)
    return false if line =~ /^\s*def /
    working_line = line.gsub(/'[^']*'/, "''").gsub(/"[^"]*"/, '""')
    working_line = remove_regexes working_line
    OPERATORS.each do |op|
      return op if matches_operator?(working_line, op)
    end
    nil
  end
  
  def self.remove_regexes(line)
    working_line = line.gsub(%r!((^|[^0-9 \t\n])\s*)/.*[^\\]/!, '\\1nil')
    working_line.gsub!(/%r(.).*[^\\]\1/, 'nil')
    working_line.gsub!(/%r\[.*[^\\]\]/, 'nil')
    working_line.gsub!(/%r\{.*[^\\]\}/, 'nil')
    working_line.gsub!(/%r\(.*[^\\]\)/, 'nil')
    working_line
  end
  
  def self.is_block_line?(line)
    line =~ /do\s*\|/ || line =~ /\{\s*\|/
  end

  def self.match?(line, context_stack)
    !!self.matching_operator(line)
  end
  
  def initialize(file, line)
    super("No operator spacing", file, line, 0, 5)
  end
  
  def fix(context_stack = nil)
    line = self.line.dup
    OPERATORS.each do |op|
      next if op == '==' && line =~ /!==/
      next if op == '=' && line =~ /!=/
      next if op == '|' && self.class.is_block_line?(line)
      embed = op.gsub(/(\+|\-|\*|\||\^)/, '\\\\\\1')
      line.gsub!(/([A-Za-z0-9_]!|[A-Za-z0-9_?])(#{embed})/, '\1 \2')
      line.gsub!(/(#{embed})([$A-Za-z0-9_?!])/, '\1 \2')
    end
    line
  end
  
  def desc
    first_operator = self.class.matching_operator(self.line)
    "Insufficient spacing around #{first_operator}"
  end
end