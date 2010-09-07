module Wool
  class Warning < Struct.new(:name, :file, :body, :line_number, :severity)
    extend Advice
    
    def self.all_warnings
      @@all_warnings ||= []
    end
    
    def self.inherited(klass)
      self.all_warnings << klass
    end
    
    def self.match?(body, context_stack)
      false
    end
    
    def fix(context_stack = nil)
      self.body
    end
    
    def desc
      self.class.name
    end
  end
  
  class LineWarning < Warning
    def self.all_warnings
      @@all_line_warnings ||= []
    end
    
    def self.inherited(klass)
      self.all_warnings << klass
    end
    alias_method :line, :body
  end
  
  class FileWarning < Warning
    def self.all_warnings
      @@all_file_warnings ||= []
    end
    
    def self.inherted(klass)
      self.all_warnings << klass
    end
  end
end

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'warnings', '**', '*.rb'))].each do |file|
  load file
end