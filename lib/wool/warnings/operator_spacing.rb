# Warning for not putting space around operators
class Wool::OperatorSpacing < Wool::LineWarning
  extend Wool::Advice::CommentAdvice
  OPERATORS = %w(+ - / * != !== = == === ~= !~ += -= *= /= ** **= ||= || && &&= &= |= | & ^)

  def self.matches_operator?(line, op)
    return false if line =~ /^\s*def /
    return false if op == '|' && is_block_line?(line)
    embed = op.gsub(/(\+|\-|\*|\||\^)/, '\\\\\\1')
    if op == '-'
      if line =~ /([A-Za-z0-9_]!|[A-Za-z0-9_?])#{embed}/ || line =~ /(#{embed})[$A-Za-z_?!]/
        op
      end
    else
      if line =~ /([A-Za-z0-9_]!|[A-Za-z0-9_?])#{embed}/ || line =~ /(#{embed})[$A-Za-z0-9_?!]/
        op
      end
    end
  end

  def self.matching_operator(line, settings = {})
    working_line = line.gsub(/'[^']*'/, "''").gsub(/"[^"]*"/, '""')
    working_line = working_line.gsub(/<<\-?[A-Za-b0-9_]+/, "''")
    working_line = remove_regexes working_line
    working_line = ignore_block_params working_line
    working_line = ignore_splat_args working_line
    working_line = ignore_to_proc_args working_line
    working_line = ignore_array_splat_idiom working_line

    OPERATORS.each do |op|
      if matches_operator?(working_line, op)
        puts "Original line: #{line}" if settings[:debug]
        puts "Working line: #{working_line}" if settings[:debug]
        return op
      end
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

  def self.ignore_block_params(line)
    line.gsub(/(\{|(do))\s*\|.*\|/, '\\1')
  end

  def self.ignore_splat_args(line)
    line.gsub(/(\(|(, ))\&([a-z][A-Za-z0-9_]*)((, )|\)|\Z)/, '\\1')
  end

  def self.ignore_array_splat_idiom(line)
    line.gsub(/\[\*([a-z][A-Za-z0-9_]*)\]/, '\\1')
  end

  def self.ignore_to_proc_args(line)
    line.gsub(/(\(|(, ))\*([a-z][A-Za-z0-9_]*)((, )|\)|\Z)/, '\\1')
  end

  def self.is_block_line?(line)
    line =~ /do\s*\|/ || line =~ /\{\s*\|/
  end

  def self.match?(line, context_stack, settings = {})
    !!self.matching_operator(line, settings)
  end
  remove_comments

  def initialize(file, line, settings={})
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