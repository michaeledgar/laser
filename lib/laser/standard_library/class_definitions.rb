class Class
  def new(*args)
    result = allocate
    result.initialize(*args)
    result
  end
  def allocate
  end
end
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
  # pure: true
  # raises: never
  def name
  end
  # pure: true
  # raises: never
  def ===(other)
  end
  def define_method(name, body=nil)
  end
  def const_set(sym, val)
  end
  def const_defined?(sym, inherit=true)
  end
  def const_get(sym, inherit=true)
  end
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
  def alias_method(to, from)
  end
end
module Kernel
  # pure: true
  # raises: never
  def singleton_class
  end
  # pure: true
  # raises: never
  def class
  end
  # pure: true
  # raises: never
  def inspect
  end
 private
  def require(path)
  end
  # raises: never
  def p(*args)
  end
  def eval(string, bndg = nil, filename = nil, lineno = nil)
  end
  def autoload(sym, path)
  end
  # raises: always
  def raise(msg_or_instance=nil, message='', callback=caller)
  end
  def gets(opt_arg_1 = :__unset__, opt_arg_2 = :__unset__)
  end
  def puts(*to_put)
  end
  # raises: never
  def block_given?
  end
  alias fail raise
end

class Object < BasicObject
  include Kernel
end

require 'basic_object'
require 'nil_false_true'
require 'exceptions'
require 'comparable'
require 'enumerable'
require 'array'
require 'string'
require 'numbers'
require '_thread'

class Range
  # this is here because early in testing Class#new wasn't smart about purity.
  # pure: true
  def self.new(start, stop, exclusive=false)
  end
  
  # pure: true
  def initialize(start, stop, exclusive=false)
  end
  
  # pure: true
  def to_a
  end
end
class Proc
end
require 'hash'
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


# ARGV: [String]
ARGV = []
# DATA: File | NilClass
DATA = nil