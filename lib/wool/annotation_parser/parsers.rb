# This is a generated file
module DefaultNode
  def constraints
    p nonterminal?
    p elements
    p text_value
    p self
    if nonterminal?
      p 'hai'
      elements.first.constraints
    else
      []
    end
  end
end

require File.expand_path(File.join(File.dirname(__FILE__), 'annotation_parser'))