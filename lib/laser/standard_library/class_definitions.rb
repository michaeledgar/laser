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
  # special: true
  def module_eval(text, filename='(eval)', line=1)
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
  def define_method(name, body=nil)
  end
  # builtin: true
  # mutation: true
  def remove_method(name, body=nil)
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
  # special: true
  def send
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
  def proc(&p)
    p
  end
  # special: true
  # predictable: maybe
  def require(path)
  end
  # raises: never
  def p(*args)
    args
  end
  def eval(string, bndg = nil, filename = nil, lineno = nil)
  end
  def autoload(sym, path)
  end
  # raises: always
  def raise(msg_or_instance=nil, message='', callback=caller)
  end
  alias fail raise
  # predictable: false
  # returns: String=
  def gets(opt_arg_1 = :__unset__, opt_arg_2 = :__unset__)
  end
  # predictable: false
  def puts(*to_put)
  end
  # raises: never
  def block_given?
  end
  alias iterator? block_given?
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
