module Wool
  class Warning < Struct.new(:name, :file, :body, :line_number, :severity)
    extend Advice
    extend ModuleExtensions
    include LexicalAnalysis

    cattr_accessor :short_name
    cattr_get_and_setter :severity, :short_desc

    def self.all_warnings
      @all_warnings ||= [self]
    end
    
    def self.all_types
      @@all_types ||= Hash.new {|h,k| h[k] = []}
    end

    def self.inherited(klass)
      self.all_warnings << klass
      next_klass = self.superclass
      while next_klass != Wool::Warning.superclass
        next_klass.send(:inherited, klass)
        next_klass = next_klass.superclass
      end
    end

    # Override in subclasses to provide a list of options to send to Trollop
    def self.options
      @options ||= [:debug, "Shows debug output from wool's scanner", {:short => '-d'}]
    end
    
    def self.opt(*args)
      self.options << args
    end
    
    def self.type(*args)
      if args.any?
        @type = args.first.to_s
        all_types[@type] << self
        self.short_name = @type[0,2].upcase + all_types[@type].size.to_s
      else
        @type
      end
    end

    def initialize(file, body, settings={})
      super(self.class.short_desc, file, body, 0, self.class.severity)
      @settings = settings
    end

    def match?(body = self.body, context_stack = nil, settings = {})
      false
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

    def indent(string, amt=nil)
      amt ||= self.body.match(/^(\s*)/)[1].size
      ' ' * amt + string.lstrip
    end

    def count_occurrences(string, substring)
      count = 0
      0.upto(string.size - substring.size) do |start|
        if string[start,substring.size] == substring
          count += 1
        end
      end
      count
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