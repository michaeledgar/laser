module Laser
  # Base class for all Laser errors. Has a few fields that are important for later
  # referencing during error reporting.
  class Error < StandardError
    ADVISORY = 1
    STYLE = 2
    MINOR_WARNING = 3
    WARNING = 4
    MAJOR_WARNING = 5
    SIMPLE_ERROR = 6
    ERROR = 7
    TRICKY_ERROR = 8
    MAJOR_ERROR = 9
    FUCKUP = 10
    
    def self.severity(new_severity)
      define_method :initialize do |msg, node|
        super(msg, node, new_severity)
      end
    end
    
    attr_accessor :ast_node, :severity
    def initialize(message, ast_node, severity = 5)
      super(message)
      @ast_node, @severity = ast_node, severity
    end
  end
  
  class ReopenedClassAsModuleError < Laser::Error
    severity MAJOR_ERROR
  end

  class ReopenedModuleAsClassError < Laser::Error
    severity MAJOR_ERROR
  end

  class ConstantInForLoopError < Laser::Error
    def initialize(const_name, ast)
      super("The constant #{const_name} is a loop variable in a for loop.",
            ast, MAJOR_ERROR)
    end
  end
  
  class UselessIncludeError < Laser::Error
    severity TRICKY_ERROR
  end
  
  class DynamicSuperclassError < Laser::Error
    severity MAJOR_ERROR
  end
  
  class NoSuchMethodError < Laser::Error
    severity MAJOR_ERROR
  end
  
  class NotInMethodError < Laser::Error
    severity FUCKUP
  end
  
  class IncompatibleArityError < Laser::Error
    severity MAJOR_ERROR
  end
end