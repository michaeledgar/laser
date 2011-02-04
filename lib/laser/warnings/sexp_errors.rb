# Warning for rescuing "Exception" or "Object".
class Laser::SexpErrorWarning < Laser::FileWarning
  severity 5
  type :dangerous
  short_desc "Error"
    
  desc { "Found error #{error.inspect}" }
  setting_accessor :error

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