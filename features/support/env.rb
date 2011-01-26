$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'laser'

require 'rspec/expectations'
require 'stringio'

def swizzling_io
  old_stdout, $stdout = $stdout, StringIO.new
  yield
  $stdout.string
ensure
  $stdout = old_stdout
end
  