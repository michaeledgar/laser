# Dependencies
require 'ripper'
require 'wool/third_party/trollop'
require 'wool/support/module_extensions'
require 'wool/advice/advice'
require 'wool/analysis/lexical_analysis'
require 'wool/analysis/sexp_analysis'
require 'wool/analysis/visitor'
require 'wool/analysis/symbol'
require 'wool/analysis/protocols'
require 'wool/analysis/signature'
require 'wool/analysis/wool_class'
require 'wool/analysis/protocol_registry'
require 'wool/analysis/scope'
require 'wool/analysis/annotations'
require 'wool/advice/comment_advice'

module Wool
  # MOVE THIS
  # TODO(adgar): move this to someplace effing sensible
  def self.initialize_global_scope
    object_class = SexpAnalysis::WoolClass.new('Object', nil)
    global = SexpAnalysis::Scope.new(nil, object_class.class_object, {'Object' => object_class})
    SexpAnalysis::Scope.const_set("GlobalScope", global) unless SexpAnalysis.const_defined?("GlobalScope")
    object_class.instance_variable_set("@scope", SexpAnalysis::Scope::GlobalScope)
    module_class = SexpAnalysis::WoolClass.new('Module')
    module_class.superclass = object_class
  end
  initialize_global_scope
end
# Runners
require 'wool/runner'
require 'wool/rake/task'
# Program logic
require 'wool/warning'
require 'wool/scanner'

module Wool
  VERSION = "0.5.0"
end