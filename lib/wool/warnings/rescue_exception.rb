# Warning for rescuing "Exception" or "Object".
class Wool::RescueExceptionWarning < Wool::FileWarning
  severity 5
  type :dangerous
  short_desc 'rescue Exception is dangerous'
  desc 'The line rescues "Exception" or "Object", which is too broad. Rescue StandardError instead.'

  def match?(file = self.body)
    find_sexps(:rescue).map do |_, types, name|
      case types[0]
      when :mrhs_new_from_args
        list = types[1] + types[2..-1]
      when Array
        list = types
      end
      list.map do |type|
        if type[0] == :var_ref &&
           type[1][0] == :@const && type[1][1] == "Exception"
          warning = RescueExceptionWarning.new(file, body)
          warning.line_number = type[1][2][1]
          warning
        end
      end.compact
    end.flatten
  end

  def fix
    body
  end
end