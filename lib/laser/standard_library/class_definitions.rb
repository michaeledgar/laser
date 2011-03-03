class String
end
class Symbol
end
class Array
end
class Proc
end
class Hash
end
# Still not sure why this exists.
class Data
end

RUBY_VERSION = '1.9.2'
$/ = "\n"
ENV = {"RUBY_VERSION"=>"ruby-1.9.2-p136"}

class << self
  def private(*args)
  end
  def public(*args)
  end
end
class Module
  def private(*args)
  end
  private :private
 private
  def include(*mods)
  end
  def extend(*mods)
  end
  def public(*args)
  end
  def protected(*args)
  end
  def attr_reader(sym, *syms)
  end
  def attr_writer(sym, *syms)
  end
  def attr_accessor(sym, *syms)
  end
  def module_function(*args)
  end
end
module Kernel
 private
  def require(path)
  end
  def p(*args)
  end
  def eval(string, bndg = nil, filename = nil, lineno = nil)
  end
  def autoload(sym, path)
  end
  def raise(msg_or_instance=nil, message='', callback=caller)
  end
  alias fail raise
end

class Object
  include Kernel
end

require 'basic_object'
require 'comparable'
require 'enumerable'
require 'array'
require 'string'
require 'numbers'
require '_thread'

class Range
end
class Proc
end
class Hash
end
class Symbol
end
class Regexp
end

class Encoding
end
class Encoding::UndefinedConversionError < EncodingError
end
class Encoding::InvalidByteSequenceError < EncodingError
end
class Encoding::ConverterNotFoundError < EncodingError
end
class Encoding::CompatibilityError < EncodingError
end

class Struct
end

class IO
  def read(len=nil)
  end
end
# STDERR: IO
STDERR = IO.new
# STDOUT: IO
STDOUT = IO.new
# STDIN: IO
STDIN = IO.new
class File < IO
end

class Time
  def self.at(x)
  end
  def self.gm(first, *rest)
  end
  def self.local(first, *rest)
  end
  class << self
    alias mktime local
  end
  def self.now
    new
  end
end
  

require 'exceptions'

# ARGV: [String]
ARGV = []
# DATA: File | NilClass
DATA = nil