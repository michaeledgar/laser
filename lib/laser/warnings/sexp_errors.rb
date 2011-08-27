class Laser::SexpErrorWarning < Laser::FileWarning
  type :dangerous
  short_desc "Error"
  desc { error.message }
  setting_accessor :error

  def line_number
    error.ast_node.line_number
  end
  
  def severity
    error.severity
  end

  def ==(other)
    super && self.error == other.error
  end

  def match?(body = self.body)
    parse.all_errors.map do |error|
      Laser::SexpErrorWarning.new(error.ast_node.file_name, body, error: error)
    end
  end
end
