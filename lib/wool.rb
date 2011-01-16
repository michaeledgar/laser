module Wool
  VERSION = "0.5.0"
  TESTS_ACTIVATED = false
  ROOT = File.expand_path(File.dirname(__FILE__))
end

# Dependencies
require 'ripper'
require 'treetop'
$:.unshift(File.expand_path(File.dirname(__FILE__)))
require 'wool/third_party/trollop'
require 'wool/support/inheritable_attributes'
require 'wool/support/acts_as_struct'
require 'wool/support/module_extensions'
require 'wool/advice/advice'
require 'wool/analysis/lexical_analysis'
require 'wool/analysis/sexp_analysis'

require 'wool/analysis/bindings'
require 'wool/analysis/protocols'
require 'wool/analysis/signature'
require 'wool/analysis/wool_class'
require 'wool/analysis/protocol_registry'
require 'wool/analysis/scope'
require 'wool/analysis/bootstrap'
# Liftoff Instructions:
# 1. Tuck in your shirt
# 2. Remove spurs
# 3. Bend at the waist
# 4. PULL UP ON THEM BOOTSTRAPS!
Wool::SexpAnalysis::Bootstrap.bootstrap
# Load the constraint engine
require 'wool/constraints/constraints'
require 'wool/annotation_parser/parsers'

require 'wool/analysis/visitor'
require 'wool/analysis/annotations'
require 'wool/advice/comment_advice'
# Runners
require 'wool/runner'
require 'wool/rake/task'
# Program logic
require 'wool/warning'
require 'wool/scanner'

Wool::SexpAnalysis.analyze_inputs([[File.join(File.dirname(__FILE__), 'wool', 'standard_library', 'class_definitions.rb'),
                                    File.read(File.join(File.dirname(__FILE__), 'wool', 'standard_library', 'class_definitions.rb'))]])