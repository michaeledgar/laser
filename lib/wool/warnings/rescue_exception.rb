# Warning for rescuing "Exception" or "Object".
class Wool::RescueExceptionWarning < Wool::FileWarning
  severity 5
  type :dangerous
  short_desc 'rescue Exception is dangerous'
  desc 'The line rescues "Exception" or "Object", which is too broad. Rescue StandardError instead.'

  def match?(file = self.body)
    false
  end

  def fix
    line
  end
end