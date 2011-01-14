# Warning for not having parens in a method declaration with arguments
class Wool::ParensOnDeclarationWarning < Wool::FileWarning
  type :style
  severity 1
  short_desc 'Missing parentheses in method declaration'
  setting_accessor :method_name
  desc do
    "The method #{method_name} should have its arguments wrapped in parentheses."
  end
  
  def match?(body = self.body)
    def_list = find_sexps(:def).select do |sym, name, args, body|
      case args.type
      when :params then args.children.any?
      when :paren then !args[1].children.any?
      end
    end.map do |sym, name, args, body|
      Wool::ParensOnDeclarationWarning.new(file, body, method_name: name[1])
    end
    sdef_list = find_sexps(:defs).select do |sym, target, op, name, args, body|
      case args.type
      when :params then args.children.any?
      when :paren then !args[1].children.any?
      end
    end.map do |sym, target, op, name, args, body|
      Wool::ParensOnDeclarationWarning.new(file, body, method_name: name[1])
    end
    def_list + sdef_list
  end
end