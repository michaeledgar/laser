# Warning for not putting space around operators
class Wool::OperatorSpacing < Wool::LineWarning
  include Wool::Advice::CommentAdvice
  OPERATORS = %w(+ - / * != !== = == === ~= !~ += -= *= /= ** **= ||= || && &&= &= |= | & ^)

  type :style
  severity 5
  short_desc 'No operator spacing'
  desc { "Insufficient spacing around #{self.match?(self.line)[2]}" }

  def match?(line = self.body, context_stack = nil, options = {})
    working_line = ignore_block_params line
    working_line = ignore_splat_args working_line
    working_line = ignore_to_proc_args working_line
    working_line = ignore_array_splat_idiom working_line
    lexed = lex(working_line)
    lexed.each_with_index do |token, idx|
      next unless token[1] == :on_op
      next if idx == lexed.size - 1  # Last token on line (continuation) is ok
      next if token[2] == '-' && [:on_float, :on_int].include?(lexed[idx+1][1])
      return token if lexed[idx+1][1] != :on_sp && lexed[idx+1][1] != :on_op
      return token if idx > 0 && ![:on_sp, :on_op].include?(lexed[idx-1][1])
    end
    nil
  end

  def ignore_block_params(line)
    line.gsub(/(\{|(do))\s*\|.*\|/, '\\1')
  end

  def ignore_splat_args(line)
    line.gsub(/(\(|(, ))\&([a-z][A-Za-z0-9_]*)((, )|\)|\Z)/, '\\1')
  end

  def ignore_array_splat_idiom(line)
    line.gsub(/\[\*([a-z][A-Za-z0-9_]*)\]/, '\\1')
  end

  def ignore_to_proc_args(line)
    line.gsub(/(\(|(, ))\*([a-z][A-Za-z0-9_]*)((, )|\)|\Z)/, '\\1')
  end

  def is_block_line?(line)
    line =~ /do\s*\|/ || line =~ /\{\s*\|/
  end

  def fix(context_stack = nil)
    line = self.line.dup
    OPERATORS.each do |op|
      next if op == '==' && line =~ /!==/
      next if op == '=' && line =~ /!=/
      next if op == '|' && self.is_block_line?(line)
      embed = op.gsub(/(\+|\-|\*|\||\^)/, '\\\\\\1')
      line.gsub!(/([A-Za-z0-9_]!|[A-Za-z0-9_?])(#{embed})/, '\1 \2')
      line.gsub!(/(#{embed})([$A-Za-z0-9_?!])/, '\1 \2')
    end
    line
  end
end