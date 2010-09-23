# Warning for using semicolons outside of class declarations.
class Wool::SemicolonWarning < Wool::LineWarning
  type :style
  def match?(line = self.body, context_stack = nil, settings = {})
    tokens = lex(line)
    find_token(line, :on_semicolon) && !find_keyword(line, "class")
  end

  def initialize(file, line, settings={})
    severity = line =~ /['"]/ ? 2 : 4
    super('Semicolon for multiple statements', file, line, 0, severity)
  end

  def fix(context_stack = nil, line = self.body)
    token = find_token(line, :on_semicolon)
    return line unless token
    location = token[0][1]
    if location == 0
      line[1..-1]
    else
      left, right = line[0..location-1], line[location + 1..-1] || ''
      right = fix(context_stack, right)
      "#{indent left}\n#{indent right}"
    end
  end

  def desc
    'The line uses a semicolon to separate multiple statements outside of a class declaration.'
  end
end