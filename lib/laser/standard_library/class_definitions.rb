class String
end
class Array
end
class Proc
end

RUBY_VERSION = '1.9.2'
$/ = "\n"

class << self
  def private(*args)
  end
  def public(*args)
  end
end
class Module
  def include(*mods)
  end
  def extend(*mods)
  end
  def private(*args)
  end
  def public(*args)
  end
  def protected(*args)
  end
end
module Kernel
 private
  def require(path)
  end
  def p(*args)
  end
end

class Object
  include Kernel
end

require 'comparable'
require 'array'
require 'string'
require 'numbers'

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
end
class File < IO
end

require 'exceptions'

# ARGV: [String]
ARGV = []
# DATA: File | NilClass
DATA = nil
