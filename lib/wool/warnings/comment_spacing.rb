# Warning for insufficient space between inline comments and code
class Wool::InlineCommentSpaceWarning < Wool::LineWarning
  OPTION_KEY = :inline_comment_space
  type :style
  short_desc 'Inline comment spacing error'
  desc { "Inline comments must be at least #{@settings[OPTION_KEY]} spaces from code." }
  opt OPTION_KEY, 'Number of spaces between code and inline comments', :default => 2

  def match?(line = self.body, context_stack = nil, settings = {})
    return false unless comment_token = find_token(:on_comment)
    comment_pos = comment_token[0][1] - 1
    left_of_comment = line[0..comment_pos]
    stripped = left_of_comment.rstrip
    return false if stripped.empty?
    padding_size = left_of_comment.size - stripped.size
    return @settings[OPTION_KEY] != padding_size
  end
end