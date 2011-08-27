class Laser::GenericLineLengthWarning < Laser::LineWarning
  cattr_accessor_with_default :line_length_limit, 80000
  type :style
  short_desc 'Line too long'
  desc { "Line length: #{line.size} > #{self.class.line_length_limit} (max)" }
  fixable true

  def self.inspect
    "Laser::GenericLineLengthWarning<#{line_length_limit}>"
  end

  def match?(body = self.body)
    !!(line.rstrip.size > self.class.line_length_limit)
  end

  def fix(content_stack = nil)
    result = handle_long_comments(self.line)
    return result if result
    result = try_to_fix_guarded_lines(self.line)
    return result if result
    self.line
  end

  def try_to_fix_guarded_lines(line)
    return nil if line !~ /\b(if|unless)\s/  # quick fast check
    code, guard = split_on_keyword(:if, :unless)
    code.rstrip!
    return nil if code.empty? || guard.empty? || code.strip == 'end'
    # check guard for closing braces
    return nil if count_occurrences(guard, '}') != count_occurrences(guard, '{')
    indent = get_indent(line)
    indent_unit = ' ' * @settings[:indent_size]

    result = code
    until guard.empty?
      condition = indent + guard.strip
      body = result.split(/\n/).map { |line| indent_unit + line}.join("\n")
      new_condition, guard = split_on_keyword(condition[indent.size+1..-1], :if, :unless)
      if new_condition.empty?
        new_condition, guard = guard.rstrip, ''
      else
        new_condition = "#{condition[indent.size,1]}#{new_condition.rstrip}"
      end
      condition = indent + new_condition unless guard.empty?
      result = condition + "\n" + body + "\n" + indent + 'end'
    end

    result
  end

  def handle_long_comments(line)
    code, comment = split_on_token(line, :on_comment)
    return nil if comment.empty?
    indent, code = code.match(/^(\s*)(.*)$/)[1..2]
    hashes, comment = comment.match(/^(#+\s*)(.*)$/)[1..2]
    comment_cleaned = fix_long_comment(indent + hashes + comment)
    code_cleaned = !code.strip.empty? ? "\n" + indent + code.rstrip : ''
    comment_cleaned + code_cleaned
  end

  def fix_long_comment(text)
    # Must have no leading text
    return nil unless text =~ /^(\s*)(#+\s*)(.*)\Z/
    indent, hashes, comment = $1, $2, $3
    indent_size = indent.size
    # The "+ 2" is (indent)#(single space)
    space_for_text_per_line = self.class.line_length_limit - (indent_size + hashes.size)
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
      unless lines[current_line].empty?
        lines[current_line] << ' '
        quota -= 1
      end
      lines[current_line] << word
      quota -= word.size
    end
    lines.map { |line| indent + hashes + line }.join("\n")
  end
end

module Laser
  def LineLengthCustomSeverity(size, severity)
    Laser.class_eval do
      if const_defined?("GenericLineLengthWarning_#{size}_#{severity}")
        return const_get("GenericLineLengthWarning_#{size}_#{severity}")
      end
      new_warning = Class.new(Laser::GenericLineLengthWarning)
      const_set("GenericLineLengthWarning_#{size}_#{severity}", new_warning)
      new_warning.line_length_limit = size
      new_warning.severity = severity
      new_warning.desc = Laser::GenericLineLengthWarning.desc
	  new_warning.type(Laser::GenericLineLengthWarning.type)
      new_warning
    end
  end

  def LineLengthMaximum(size)
    (@table ||= {})[size] ||= LineLengthCustomSeverity(size, 8)
  end

  def LineLengthWarning(size)
    (@table ||= {})[size] ||= LineLengthCustomSeverity(size, 3)
  end
  module_function :LineLengthMaximum, :LineLengthWarning, :LineLengthCustomSeverity
end
