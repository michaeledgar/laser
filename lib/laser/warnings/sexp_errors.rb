# Warning for rescuing "Exception" or "Object".
class Laser::SexpErrorWarning < Laser::FileWarning
  type :dangerous
  short_desc "Error"
    
  desc { error.message }
  setting_accessor :error

  def line_number
    error.ast_node.source_begin && error.ast_node.source_begin[0]
  end
  
  def severity
    error.severity
  end

  def ==(other)
    super && self.error == other.error
  end

  def match?(body = self.body)
    parse.all_errors.map do |error|
      p error
      Laser::SexpErrorWarning.new(file, body, error: error)
    end
  end
end