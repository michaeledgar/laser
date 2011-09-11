# Warning for rescuing "Exception" or "Object".
class Laser::RescueExceptionWarning < Laser::FileWarning
  severity 5
  type :dangerous
  short_desc 'rescue Exception is dangerous'
  desc 'The line rescues "Exception" or "Object", which is too broad. Rescue StandardError instead.'
  setting_accessor :position
  fixable true

  def match?(body = self.body)
    find_sexps(:rescue).map do |_, types, name|
      next if types.nil?
      case types[0]
      when :mrhs_new_from_args
        list = types[1] + types[2..-1]
      when Array
        list = types
      end
      list.map do |type|
        if type[0] == :var_ref &&
           type[1][0] == :@const && type[1][1] == "Exception"
          warning = Laser::RescueExceptionWarning.new(file, body, position: type[1][2])
          warning.position[0] -= 1
          warning.line_number = type[1][2][1]
          warning
        end
      end
    end.flatten.compact
  end

  def fix(body = self.body)
    result = ""
    all_lines = body.lines.to_a
    result << all_lines[0..position[0]-1].join if position[0]-1 >= 0
    result << all_lines[position[0]][0,position[1]]
    result << 'StandardError'
    if trailing = all_lines[position[0]][position[1] + 'Exception'.size .. -1]
      result << trailing
    end
    result << all_lines[position[0]+1..-1].join if position[0]+1 < all_lines.size
    result
  end
end
