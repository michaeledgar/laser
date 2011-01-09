# Warning for not having parens in a method declaration with arguments
class Wool::AssignmentInConditionWarning < Wool::FileWarning
  type :gotcha
  severity 3
  short_desc 'Assignment in condition not in parentheses'
  
  def match?(body = self.body)
    to_search = find_sexps(:if) + find_sexps(:unless) + find_sexps(:elsif)
    to_search.map do |sym, condition, success_body, failure_body|
      assignments = find_sexps(:assign, condition)
      assignments.reject do |node|
        node.ancestors.map(&:type).include?(:paren)
      end
    end.compact.flatten.map do |node|
      AssignmentInConditionWarning.new(file, body)
    end
  end
end