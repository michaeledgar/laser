module Wool
  class Warning < Struct.new(:name, :file, :body, :line_number, :severity)
    extend Advice
    
    def self.all_warnings
      @@all_warnings ||= [Wool::Warning]
    end
    
    def self.inherited(klass)
      self.all_warnings << klass
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
      self.fix != self.body
    end
    
    def desc
      "#{self.class.name} #{file}:#{line_number} (#{severity})"
    end
  end
  
  class LineWarning < Warning
    def self.all_warnings
      @@all_line_warnings ||= []
    end
    alias_method :line, :body
    
    def self.options
      []
    end
  end
  
  class FileWarning < Warning
    def self.all_warnings
      @@all_file_warnings ||= []
    end
    
    def self.options
      []
    end
  end
end

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'warnings', '**', '*.rb'))].each do |file|
  load file
end