# Dependencies
require 'ripper'
require 'wool/third_party/trollop'
require 'wool/support/module_extensions'
require 'wool/advice/advice'
require 'wool/analysis/lexical_analysis'
require 'wool/analysis/sexp_analysis'

require 'wool/analysis/symbol'
require 'wool/analysis/protocols'
require 'wool/analysis/signature'
require 'wool/analysis/wool_class'
require 'wool/analysis/protocol_registry'
require 'wool/analysis/scope'

# Liftoff Instructions:
# 1. Tuck in your shirt
# 2. Remove spurs
# 3. Bend at the waist
# 4. PULL UP ON THEM BOOTSTRAPS!
Wool::SexpAnalysis::ClassRegistry.initialize_global_scope
require 'wool/analysis/visitor'
require 'wool/analysis/annotations'
require 'wool/advice/comment_advice'
# Runners
require 'wool/runner'
require 'wool/rake/task'
# Program logic
require 'wool/warning'
require 'wool/scanner'

module Wool
  VERSION = "0.5.0"
end