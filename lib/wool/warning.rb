module Wool
  class Warning < Struct.new(:name, :file, :body, :line_number, :severity)
    extend Advice

    def self.all_warnings
      @all_warnings ||= [self]
    end

    def self.inherited(klass)
      self.all_warnings << klass
      next_klass = self.superclass
      while next_klass != Wool::Warning.superclass
        next_klass.send(:inherited, klass)
        next_klass = next_klass.superclass
      end
    end

    def self.match?(body, context_stack, settings = {})
      false
    end

    # Override in subclasses to provide a list of options to send to Trollop
    def self.options
      [:debug, "Shows debug output from wool's scanner", {:short => '-d'}]
    end

    def fix(context_stack = nil)
      self.body
    end

    def fixable?
      self.fix != self.body rescue false
    end

    def desc
      "#{self.class.name} #{file}:#{line_number} (#{severity})"
    end

    def split_on_char_outside_literal(input, regex)
      last_char = ''
      in_string = in_regex = is_backslash = false
      escape_string = nil
      input.size.times do |idx|
        char = input[idx,1]
        if char == '/'
          in_regex = !in_regex unless last_char =~ /\d/
        elsif !is_backslash && char == "'" || char == '"'
          if char == escape_string || escape_string.nil?
            in_string = !in_string
            escape_string = in_string ? char : nil
          end
        elsif (input[idx..-1] =~ regex) == 0 && !(in_string || in_regex)
          return [input[0,idx], input[idx..-1]]
        end
        is_backslash = char == '\\' && !is_backslash
      end
      return [input, '']
    end
    
    def get_indent(line)
      line =~ /^(\s*).*$/ ? $1 : ''
    end
  end

  class LineWarning < Warning
    alias_method :line, :body
    def self.options
      []
    end
  end

  class FileWarning < Warning
    def self.options
      []
    end
  end
end

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'warnings', '**', '*.rb'))].each do |file|
  load file
end