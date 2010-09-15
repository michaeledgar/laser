# Warning for using semicolons outside of class declarations.
class Wool::SemicolonWarning < Wool::LineWarning
  extend Wool::Advice::CommentAdvice

  def self.match?(line, context_stack, settings = {})
    tokens = lex(line)
    has_token?(line, :on_semicolon) && !has_keyword?(line, "class")
  end
  remove_comments

  def initialize(file, line, settings={})
    severity = line =~ /['"]/ ? 2 : 4
    super('Semicolon for multiple statements', file, line, 0, severity)
  end

  def desc
    'The line uses a semicolon to separate multiple statements outside of a class declaration.'
  end
end