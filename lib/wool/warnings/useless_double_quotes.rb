  # Warning for using semicolons outside of class declarations.
class Wool::UselessDoubleQuotesWarning < Wool::FileWarning
  type :style
  severity 1
  short_desc 'Useless double quotes'
  desc { "The string #{quoted_string} should be wrapped in single quotes for efficiency." }

  def quoted_string
    (@opts ||= {})[:quoted_string]
  end
  
  def match?(body = self.body)
    list = find_sexps(:string_content)
    list.map do |sym, *parts|
      next if parts.size != 1
      inner_sym, text, pos = parts.first
      next unless inner_sym == :@tstring_content && text !~ /(\\)|(\#\{)|(')/
      previous_char = body.lines.to_a[pos[0] - 1][pos[1]-1,1]
      if previous_char == '"' || (previous_char == '{' && body.lines.to_a[pos[0] - 1][pos[1]-3,2] == '%Q')
        UselessDoubleQuotesWarning.new(file, pos[0], :quoted_string => text)
      end
    end.compact
  end

  #def fix
  #
  #end
end