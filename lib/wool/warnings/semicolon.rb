# Warning for using semicolons outside of class declarations.
class Wool::SemicolonWarning < Wool::LineWarning
  type :style
  short_desc 'Semicolon for multiple statements'
  desc 'The line uses a semicolon to separate multiple statements outside of a class declaration.'

  def initialize(*args)
    super
    self.severity = line =~ /['"]/ ? 2 : 4
  end

  def match?(line = self.body)
    !!(find_token(line, :on_semicolon) && !find_keyword(line, :class))
  end

  def fix(line = self.body)
    left, right = split_on_token(line, :on_semicolon)
    return line if right.empty?
    return right[1..-1] if left.empty?

    right = fix(right[1..-1])
    "#{indent left}\n#{indent right}"
  end
end