module Laser
  VERSION = "0.5.0"
  TESTS_ACTIVATED = false
  ROOT = File.expand_path(File.dirname(__FILE__))
  SETTINGS = {}
end

# Dependencies
require 'ripper'
require 'treetop'
require 'ripper-plus'
$:.unshift(File.expand_path(File.dirname(__FILE__)))
require 'laser/third_party/trollop'
require 'laser/third_party/stream'
require 'laser/third_party/axiom_of_choice'
require 'laser/third_party/rgl/dot'  # KILLME
require 'laser/third_party/rgl/bidirectional'
require 'laser/third_party/rgl/depth_first_spanning_tree'
require 'laser/third_party/rgl/control_flow'
require 'laser/support/inheritable_attributes'
require 'laser/support/acts_as_struct'
require 'laser/support/module_extensions'
require 'laser/support/object_regex'
require 'laser/support/frequency'
require 'laser/analysis/errors'
require 'laser/analysis/lexical_analysis'

require 'laser/analysis/sexp_extensions/type_inference'
require 'laser/analysis/sexp_extensions/constant_extraction'
require 'laser/analysis/sexp_extensions/source_location'
require 'laser/analysis/sexp_extensions/method_resolution'

require 'laser/analysis/sexp'
require 'laser/analysis/sexp_analysis'

require 'laser/analysis/arity'
require 'laser/analysis/argument_expansion'
require 'laser/analysis/method_call'
require 'laser/analysis/assignment_expression'
require 'laser/analysis/bindings'
require 'laser/analysis/signature'
require 'laser/analysis/laser_class'
require 'laser/analysis/protocol_registry'
require 'laser/analysis/scope'
require 'laser/analysis/comments'
require 'laser/analysis/control_flow'
require 'laser/analysis/bootstrap'
# Liftoff Instructions:
# 1. Tuck in your shirt
# 2. Remove spurs
# 3. Bend at the waist
# 4. PULL UP ON THEM BOOTSTRAPS!
Laser::SexpAnalysis::Bootstrap.bootstrap
# Load the type engine
require 'laser/types/types'
Laser::SexpAnalysis::Bootstrap.bootstrap_magic
require 'laser/annotation_parser/parsers'

require 'laser/analysis/visitor'
require 'laser/analysis/annotations'
require 'laser/analysis/scope_annotation'
# Runners
require 'laser/runner'
require 'laser/rake/task'
# Program logic
require 'laser/warning'
require 'laser/scanner'

%w(class_definitions.rb).map do |file|
  path = File.join(File.dirname(__FILE__), 'laser', 'standard_library', file)
  [path, File.read(path)]
end.tap do |tuples|
  trees = Laser::SexpAnalysis.analyze_inputs(tuples)
  trees.each do |filename, tree|
    if tree.all_errors != []
      $stderr.puts "Default file #{filename} had these errors:"
      PP.pp(tree.all_errors, $stderr)
      exit 1
    end
  end
end