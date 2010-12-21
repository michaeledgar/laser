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

# Runs a shit-ton of expectations common among annotations. Since an annotaiton
# just adds an attribute to a Sexp, we have a very common set of examples o
# the form:
#   tree[0].new_attribute.should == some_val
#   tree[1][0].new_attribute.should == some_val
#   ...
#   tree[2][2].new_attribute.should == cool_inferred_val
# and so on. A ton of repetitiveness can be captured by using hashes in the form:
#
#     {:new_attribute => { some_val => [tree[1][0], tree[0], ...],
#                        { cool_inferred_val => [tree[2][2], ...] }}}
#
# Each attribute is a key in the toplevel hash, and each possible value is a key
# in the second-level hash. Technically this doesn't remove all duplication, but
# it's good.
def expectalot(expectation)
  messages = expectation.keys
  messages.each do |message|
    examples = expectation[message]
    examples.each do |expected_value, recipients|
      recipients.each do |recipient|
        recipient.send(message).should == expected_value
      end
    end
  end 
end