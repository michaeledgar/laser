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

Wool::SexpAnalysis::ClassRegistry.initialize_global_scope
# Runners
require 'wool/runner'
require 'wool/rake/task'
# Program logic
require 'wool/warning'
require 'wool/scanner'

module Wool
  VERSION = "0.5.0"
end