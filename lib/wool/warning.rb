module Wool
  class Warning < Struct.new(:name, :file, :line, :line_number, :severity)
    def self.all_warnings
      @all_warnings ||= []
    end
    
    def self.inherited(klass)
      self.all_warnings << klass
    end
    
    def self.match?(line, context_stack)
      false
    end
    
    def fix(context_stack)
      self.line
    end
    
    def desc
      self.class.name
    end
  end
end

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'warnings', '**', '*.rb'))].each do |file|
  load file
end