class Wool::GenericLineLengthWarning < Wool::LineWarning
  def self.line_length_limit
    @line_length_limit ||= 80000
  end
  def self.line_length_limit=(val)
    @line_length_limit = val
  end
  def self.inspect
    "Wool::GenericLineLengthWarning<#{line_length_limit}>"
  end
  class << self
    attr_accessor :severity
  end

  def self.match?(line, context, settings = {})
    !!(line.size > self.line_length_limit)
  end

  def initialize(file, line, settings={})
    super('Line too long', file, line, 0, self.class.severity)
    @settings = settings
  end

  def fix(content_stack = nil)
    result = handle_long_comments(self.line)
    return result if result
    result = try_to_fix_guarded_lines(self.line)
    return result if result
    self.line
  end

  def try_to_fix_guarded_lines(line)
    return nil unless line =~ /\b(if|unless)\s/  # quick fast check
    code, guard = split_on_char_outside_literal(line, /(\b|\s)(if|unless)\b/)
    return nil unless guard.any?
    # check guard for closing braces
    return nil if count_occurrences(guard, '}') != count_occurrences(guard, '{')
    indent = get_indent(line)
    condition = indent + guard.strip
    body = indent + (' ' * @settings[:indent_size]) + code.strip
    return condition + "\n" + body + "\n" + indent + 'end'
    # tree = RubyParser.new.parse(line)
    # if tree[0] == :if && (tree[2].nil? ^ tree[3].nil?)
    #   method = tree[2] ? 'if' : 'unless'
    #   # rewrite as if/then
    #   indent = get_indent(line)
    #   r2r = Ruby2Ruby.new
    #   condition = indent + method + ' ' + r2r.process(tree[1])
    #   body_tree = tree[2] || tree[3]
    #   body = r2r.process(body_tree).split(/\n/).map do |line|
    #     indent + (' ' * @settings[:indent_size]) + line.strip
    #   end
    #   return condition + body.join("\n") + indent + 'end'
    # end
  end

  def handle_long_comments(line)
    code, comment = split_on_char_outside_literal(line, /#/)
    return nil unless comment.any?
    indent, code = code.match(/^(\s*)(.*)$/)[1..2]
    hashes, comment = comment.match(/^(#+\s*)(.*)$/)[1..2]
    comment_cleaned = fix_long_comment(indent + hashes + comment)
    code_cleaned = code.strip.any? ? "\n" + indent + code.rstrip : ''
    comment_cleaned + code_cleaned
  end

  def fix_long_comment(text)
    # Must have no leading text
    return nil unless text =~ /^(\s*)(#+\s*)(.*)\Z/
    indent, hashes, comment = $1, $2, $3
    indent_size = indent
    # The "+ 2" is (indent)#(single space)
    space_for_text_per_line = self.class.line_length_limit - (indent.size + hashes.size)
    lines = ['']
    words = comment.split(/\s/)
    quota = space_for_text_per_line
    current_line = 0
    while words.any?
      word = words.shift
      # break on word big enough to make a new line, unless its the first word
      if quota - (word.size + 1) < 0 && quota < space_for_text_per_line
        current_line += 1
        lines << ''
        quota = space_for_text_per_line
      end
      if lines[current_line].any?
        lines[current_line] << ' '
        quota -= 1
      end
      lines[current_line] << word
      quota -= word.size
    end
    lines.map { |line| indent + hashes + line }.join("\n")
  end

  def desc
    "Line length: #{line.size} > #{self.class.line_length_limit} (max)"
  end
end

module Wool
  def LineLengthCustomSeverity(size, severity)
    new_warning = Class.new(Wool::GenericLineLengthWarning)
    new_warning.line_length_limit = size
    new_warning.severity = severity
    new_warning
  end

  def LineLengthMaximum(size)
    (@table ||= {})[size] ||= LineLengthCustomSeverity(size, 8)
  end

  def LineLengthWarning(size)
    (@table ||= {})[size] ||= LineLengthCustomSeverity(size, 3)
  end
  module_function :LineLengthMaximum, :LineLengthWarning, :LineLengthCustomSeverity
end