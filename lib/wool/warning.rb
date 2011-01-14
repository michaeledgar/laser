module Wool
  class Warning < Struct.new(:name, :file, :body, :line_number, :severity)
    extend Advice
    extend ModuleExtensions
    include LexicalAnalysis
    include SexpAnalysis

    cattr_accessor :short_name
    cattr_accessor_with_default :match_filters, []
    cattr_get_and_setter :severity, :short_desc, :desc
    attr_accessor :settings

    desc { "#{self.class.name} #{file}:#{line_number} (#{severity})" }

    # This tracks all subclasses (and subclasses of subclasses, etc). Plus, this
    # method is inherited, so Wool::LineWarning.all_subclasses will have all
    # subclasses of Wool::LineWarning!
    def self.all_warnings
      @all_warnings ||= [self]
    end
    
    # Returns all "concrete" warnings, that is, those that have an actual
    # implementation. No meta-warnings like FileWarning/LineWarning.
    #
    # @return [Array<Class>] the concrete warnings you might want to use
    def self.concrete_warnings
      all_warnings - [self, FileWarning, LineWarning]
    end

    # All types should be shared and modified by *all* subclasses. This makes
    # Wool::Warning.all_types a global registry.
    def self.all_types
      @@all_types ||= Hash.new {|h,k| h[k] = []}
    end

    # When a Warning subclass is subclassed, store the subclass and inform the
    # next superclass up the inheritance hierarchy.
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
      @options ||= [:debug, "Shows debug output from wool's scanner", {short: '-d'}]
    end

    # Adds an option in Trollop format.
    def self.opt(*args)
      self.options << args
    end

    # Modified cattr_get_and_setter that updates the class's short_name and
    # registers the class as a member of the given type.
    def self.type(*args)
      if args.any?
        @type = args.first.to_s
        all_types[@type] << self
        self.short_name = @type[0,2].upcase + all_types[@type].size.to_s
      else
        @type
      end
    end

    # Adds an instance method that extracts a key from the settings of
    # the warning. This is a simple way of storing metadata about the
    # discovered error/issue for presentational purposes.
    def self.setting_accessor(*syms)
      syms.each { |sym| class_eval("def #{sym}\n  @settings[#{sym.inspect}]\nend") }
    end

    # Default initializer.
    def initialize(file, body, settings={})
      super(self.class.short_desc, file, body, 0, self.class.severity)
      @settings = settings
    end

    def match?(body = self.body)
      false
    end

    def generated_warnings(*args)
      case match_result = match?(*args)
      when Array then match_result
      when false, nil then []
      else [self]
      end
    end

    def fix
      self.body
    end

    def fixable?
      self.fix != self.body rescue false
    end

    def desc
      case desc = self.class.desc
      when String then desc
      when Proc then instance_eval(&self.class.desc)
      end
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

    def get_indent(line = self.body)
      line =~ /^(\s*).*$/ ? $1 : ''
    end
  end

  class LineWarning < Warning
    alias_method :line, :body
    def self.options
      @options ||= []
    end
  end

  class FileWarning < Warning
    def self.options
      @options ||= []
    end
  end
end

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'warnings', '**', '*.rb'))].each do |file|
  load file
end