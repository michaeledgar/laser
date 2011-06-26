# Warning for rescuing "Exception" or "Object".
class Laser::HashSymbol19Warning < Laser::FileWarning
  severity 1
  type :style
  short_desc 'symbol hash key in 1.9 style'
  desc { "The Hash key #{token[1]} is used in a Hash literal in 1.9 style." }
  fixable true
  setting_accessor :token
  setting_accessor :line_adjustments

  def match?(body = self.body)
    line_adjustments = Hash.new(0)
    lex.map do |token|
      if token.type == :on_label
        Laser::HashSymbol19Warning.new(file, body,
            token: token,
            line_adjustments: line_adjustments)
      end
    end.compact
  end

  def fix(body = self.body)
    lines = body.lines.to_a  # eagerly expand lines
    label = token
    lines[label.line - 1][label.col + line_adjustments[label.line],label.body.size] = ":#{label.body[0..-2]} =>"
    line_adjustments[label.line] += 3  # " =>" is inserted and is 3 chars
    lines.join
  end
end