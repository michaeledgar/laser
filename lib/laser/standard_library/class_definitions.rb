class Class < Module
  # special: true
  # pure: true
  def self.new(superklass=Object)
  end
  def new(*args)
    result = allocate
    result.send(:initialize, *args)
    result
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
  # returns: Array
  def self.new(arg1=0, val=nil)
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
  # special: true
  def module_eval(text, filename='(eval)', line=1)
  end
  # pure: true
  # raises: never
  # builtin: true
  # returns: String
  def name
  end
  # pure: true
  # raises: never
  # builtin: true
  # returns: Boolean
  def ===(other)
  end
  # pure: true
  # builtin: true
  def instance_method(name)
  end
  # pure: true
  # builtin: true
  def method_defined?(name)
  end
  # pure: true
  # builtin: true
  def instance_methods(include_super = true)
  end
  # pure: true
  # builtin: true
  def public_instance_method(name)
  end
  # pure: true
  # builtin: true
  def public_instance_methods(include_super = true)
  end
  # pure: true
  # builtin: true
  def protected_instance_methods(include_super = true)
  end
  # pure: true
  # builtin: true
  def private_instance_methods(include_super = true)
  end
  # special: true
  # mutation: true
  # yield_usage: optional
  def define_method(name, body=nil)
  end
  # builtin: true
  # mutation: true
  def remove_method(name)
  end
  # builtin: true
  # mutation: true
  def undef_method(name)
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
  # pure: true
  def attr_reader(*syms)
    syms.each do |sym|
      module_eval("def #{sym}; @#{sym}; end")
    end
  end
  # pure: true
  def attr_writer(*syms)
    syms.each do |sym|
      module_eval("def #{sym}=(val); @#{sym} = val; end")
    end
  end
  # pure: true
  def attr_accessor(*syms)
    attr_reader(*syms)
    attr_writer(*syms)
  end
  # builtin: true
  # mutation: true
  def module_function(*args)
  end
  # builtin: true
  # mutation: true
  # returns: Module
  def alias_method(to, from)
  end
  alias attr attr_reader
end

module Kernel
  # special: true
  def require(path)
  end
end

require 'kernel'
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
require 'proc'
require 'hash'
class Symbol
end
class Regexp
  # pure: true
  # builtin: true
  def self.new(body, opts=nil)
  end
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
  # predictable: false
  def read(len=nil)
  end
end

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
