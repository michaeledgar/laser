  # Warning for using semicolons outside of class declarations.
class Wool::UselessDoubleQuotesWarning < Wool::FileWarning
  type :style
  severity 1
  short_desc 'Useless double quotes'
  setting_accessor :quoted_string, :uses_q_braces
  desc do
    if uses_q_braces
    then "The string %q{#{quoted_string}} can be written with lowercase q for efficiency."
    else "The string '#{quoted_string}' can be wrapped in single quotes for efficiency."
    end
  end
  
  def match?(body = self.body)
    list = find_sexps(:string_content)
    list.map do |sym, *parts|
      next if parts.size != 1  # ignore multiparts as they're fine
      inner_sym, text, pos = parts.first
      # skip if the string has a backslash or an apostrophe in it.
      next unless inner_sym == :@tstring_content && text !~ /(\\)|(')/
      
      previous_char = body.lines.to_a[pos[0] - 1][pos[1]-1,1]
      uses_q_braces = (previous_char == '{' && body.lines.to_a[pos[0] - 1][pos[1]-3,2] == '%Q')
      if previous_char == '"' || uses_q_braces
        warning = Wool::UselessDoubleQuotesWarning.new(
            file, body, :quoted_string => text, :uses_q_braces => uses_q_braces)
        warning.line_number = pos[0]
        warning
      end
    end.compact
  end

  def fix(body = self.body)
    body.gsub("\"#{quoted_string}\"", "'#{quoted_string}'").
         gsub("%Q{#{quoted_string}}", "%q{#{quoted_string}}")
  end
end