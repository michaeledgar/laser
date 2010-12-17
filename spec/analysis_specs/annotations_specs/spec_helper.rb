require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def is_sexp?(sexp)
  SexpAnalysis::Sexp === sexp
end

def all_sexps_in_subtree(tree)
  to_visit = tree.children.dup
  visited = Set.new
  while to_visit.any?
    todo = to_visit.shift
    next unless is_sexp?(todo)
    
    case todo[0]
    when Array
      to_visit.concat todo
    when Symbol
      to_visit.concat todo.children
      visited << todo
    end
  end
  visited
end