# Warning for insufficient space between inline comments and code
class Wool::InlineCommentSpaceWarning < Wool::LineWarning
  OPTION_KEY = :inline_comment_space
  DEFAULT_SPACE = 2
  type :style
  short_desc 'Inline comment spacing error'
  desc { "Inline comments must be at least #{@settings[OPTION_KEY]} spaces from code." }
  opt OPTION_KEY, 'Number of spaces between code and inline comments', :default => DEFAULT_SPACE

  def match?(line = self.body, settings = {})
    return false unless comment_token = find_token(:on_comment)
    comment_pos = comment_token[0][1] - 1
    left_of_comment = line[0..comment_pos]
    stripped = left_of_comment.rstrip
    return false if stripped.empty?
    padding_size = left_of_comment.size - stripped.size
    return spacing != padding_size
  end

  def fix
    comment_token = find_token(:on_comment)
    comment_pos = comment_token[0][1] - 1
    left_of_comment = line[0..comment_pos].rstrip
    left_of_comment + (' ' * spacing) + comment_token.last
  end

  def spacing
    @settings[OPTION_KEY] || DEFAULT_SPACE
  end
end