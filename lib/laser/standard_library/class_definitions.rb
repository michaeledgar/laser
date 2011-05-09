class Class < Module
  # special: true
  # pure: true
  def self.new(superklass=Object)
  end
  def new(*args)
    result = allocate
    result.initialize(*args)
    result
  end
  # special: true
  # pure: true
  def allocate
  end
  # pure: true
  # builtin: true
  def superclass
  end
end
class String
end
class Symbol
end
class Array
  # builtin: true
  def self.new(arg)
  end
end
class Proc
end
class Hash
end
# Still not sure why this exists.
class Data
end
# 
RUBY_VERSION = '1.9.2'
$/ = "\n"
ENV = {"RUBY_VERSION"=>"ruby-1.9.2-p136"}

class << self
  # special: true
  def private(*args)
  end
  # special: true
  def public(*args)
  end
end
class Module
  # special: true
  # pure: true
  def self.new
  end
  # pure: true
  # raises: never
  # builtin: true
  def name
  end
  # pure: true
  # raises: never
  # builtin: true
  def ===(other)
  end
  # builtin: true
  # mutation: true
  def define_method(name, body=nil)
  end
  # builtin: true
  # mutation: true
  def const_set(sym, val)
  end
  # builtin: true
  def const_defined?(sym, inherit=true)
  end
  # builtin: true
  def const_get(sym, inherit=true)
  end
  # builtin: true
  # mutation: true
  def private(*args)
  end
  private :private
 private
  # builtin: true
  # mutation: true
  def include(*mods)
  end
  # builtin: true
  # mutation: true
  def extend(*mods)
  end
  # builtin: true
  # mutation: true
  def public(*args)
  end
  # builtin: true
  # mutation: true
  def protected(*args)
  end
  # special: true
  def attr_reader(sym, *syms)
  end
  # special: true
  def attr_writer(sym, *syms)
  end
  # special: true
  def attr_accessor(sym, *syms)
  end
  # builtin: true
  # mutation: true
  def module_function(*args)
  end
  # builtin: true
  # mutation: true
  def alias_method(to, from)
  end
end
module Kernel
  # pure: true
  # builtin: true
  def eql?(other)
  end
  # pure: true
  # builtin: true
  def equal?(other)
  end
  # pure: true
  # raises: never
  # builtin: true
  def singleton_class
  end
  # pure: true
  # raises: never
  # builtin: true
  def class
  end
  # pure: true
  # raises: never
  def inspect
  end
  # builtin: true
  def instance_variable_get(name)
  end
  # builtin: true
  def instance_variable_defined?(name)
  end
  # builtin: true
  # mutation: true
  def instance_variable_set(name, val)
  end
 private
  # special: true
  # predictable: maybe
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
  # predictable: false
  def gets(opt_arg_1 = :__unset__, opt_arg_2 = :__unset__)
  end
  # predictable: false
  def puts(*to_put)
  end
  # raises: never
  def block_given?
  end
  alias fail raise
end

require 'basic_object'
require 'nil_false_true'
require 'exceptions'
require 'comparable'
require 'enumerable'
require 'array'
require 'string'
require 'symbol'
require 'numbers'
require '_thread'

class Range
  # this is here because early in testing Class#new wasn't smart about purity.
  # pure: true
  # builtin: true
  def self.new(start, stop, exclusive=false)
  end
  
  # pure: true
  # builtin: true
  def initialize(start, stop, exclusive=false)
  end
  
  # pure: true
  # builtin: true
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
# class Encoding::UndefinedConversionError < EncodingError
# end
# class Encoding::InvalidByteSequenceError < EncodingError
# end
# class Encoding::ConverterNotFoundError < EncodingError
# end
# class Encoding::CompatibilityError < EncodingError
# end

class Struct
end

class IO
  # predictable: false
  def read(len=nil)
  end
end
# STDERR: IO
# STDERR = IO.new
# STDOUT: IO
# STDOUT = IO.new
# STDIN: IO
# STDIN = IO.new
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
  # predictable: false
  def self.now
    new
  end
end


# ARGV: [String]
ARGV = []
# DATA: File | NilClass
DATA = nil