# Dependencies
require 'ripper'
require 'wool/third_party/trollop'
require 'wool/support/module_extensions'
require 'wool/advice/advice'
require 'wool/analysis/lexical_analysis'
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