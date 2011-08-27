# Warning for not having parens in a method declaration with arguments
class Laser::AssignmentInConditionWarning < Laser::FileWarning
  type :gotcha
  severity 3
  short_desc 'Assignment in condition not in parentheses'
  
  def match?(body = self.body)
    to_search = find_sexps(:if) + find_sexps(:unless) + find_sexps(:elsif)
    to_search.map do |sym, condition, _, _|
      assignments = find_sexps(:assign, condition)
      assignments.reject do |node|
        ancestors = node.ancestors.map(&:type)
        path_to_node = ancestors[ancestors.rindex(sym)..-1]
        path_to_node.include?(:paren)
      end
    end.compact.flatten.map do |node|
      Laser::AssignmentInConditionWarning.new(file, body)
    end
  end
end
