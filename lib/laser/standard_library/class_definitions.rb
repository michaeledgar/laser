RUBY_VERSION = '1.9.2'
$/ = "\n"
module Kernel
  def p(*args)
  end
end
module Comparable
  def >(other)
  end
  def >=(other)
  end
  def <(other)
  end
  def <=(other)
  end
  def ==(other)
  end
  def between?(min, max)
  end
end
class Object
  include Kernel
end

class Exception < Object
end
class SystemExit < Exception
end
# class fatal < Exception
# end
class SignalException < Exception
end
class Interrupt < SignalException
end
class StandardError < Exception
end
class TypeError < StandardError
end
class ArgumentError < StandardError
end
class IndexError < StandardError
end
class KeyError < IndexError
end
class RangeError < StandardError
end
class ScriptError < Exception
end
class SyntaxError < ScriptError
end
class LoadError < ScriptError
end
class NotImplementedError < ScriptError
end
class NameError < StandardError
end
class NoMethodError < NameError
end
class RuntimeError < StandardError
end
class SecurityError < Exception
end
class NoMemoryError < Exception
end
class EncodingError < StandardError
end
class SystemCallError < StandardError
end
class ZeroDivisionError < StandardError
end
class FloatDomainError < RangeError
end
class RegexpError < StandardError
end
class IOError < StandardError
end
class EOFError < IOError
end
class LocalJumpError < StandardError
end
class SystemStackError < Exception
end
module Math
  class DomainError < StandardError
  end
end
class StopIteration < IndexError
end
class ThreadError < StandardError
end
class FiberError < StandardError
end


class Hash
end
class Array
  def &(other_ary)
  end
  def |(other_ary)
  end
  def *(int_or_str)
  end
  def +(other_ary)
  end
  def -(other_ary)
  end
  def <<(obj)
  end
  def <=>(other_ary)
  end
  def ==(other_ary)
  end
  def [](*args)
  end
  def []=(*args)
  end
  def assoc(obj)
  end
  def at(index)
  end
  def clear
  end
  def collect
  end
  def collect!
  end
  def combination(n)
  end
  def compact
  end
  def compact!
  end
  def concat(other_ary)
  end
  def count(*args)
  end
  def cycle(n=nil)
  end
  def delete(obj)
  end
  def delete_at(index)
  end
  def delete_if
  end
  def drop(n)
  end
  def drop_while
  end
  def each
  end
  def each_index
  end
  def empty?
  end
  def eql?(other_ary)
  end
  def fetch(*args)
  end
  def fill(*args)
  end
  def find_index(*args)
  end
  def first(*args)
  end
  def flatten(*args)
  end
  def flatten!(*args)
  end
  def frozen?
  end
  def hash
  end
  def include?(obj)
  end
  def index(*args)
  end
  def insert(index, *obj)
  end
  def inspect
  end
  def join(sep=$,)
  end
  def keep_if
  end
  def last(*arg)
  end
  def length
  end
  def map
  end
  def map!
  end
  def pack(template_string)
  end
  def permutation(*arg)
  end
  def pop(*arg)
  end
  def product(other_ary, *rest)
  end
  def push(obj, *rest)
  end
  def rassoc(obj)
  end
  def reject
  end
  def reject!
  end
  def repeated_combination(n)
  end
  def repeated_permutation(n)
  end
  def replace(other_ary)
  end
  def reverse
  end
  def reverse!
  end
  def reverse_each
  end
  def rindex(*obj_or_not)
  end
  def rotate(n=1)
  end
  def rotate!(cnt=1)
  end
  def sample(*n_or_not)
  end
  def select
  end
  def select!
  end
  def shift(*n_or_not)
  end
  def shuffle
  end
  def shuffle!
  end
  def size
  end
  def slice(*args)
  end
  def slice!(*args)
  end
  def sort
  end
  def sort!
  end
  def sort_by!
  end
  def take(n)
  end
  def take_while
  end
  def to_a
  end
  def to_ary
  end
  def to_s
  end
  def transpose
  end
  def uniq
  end
  def uniq!
  end
  def unshift(obj, *objs)
  end
  def values_at(selector, *selectors)
  end
  def zip(arg, *args)
  end
end
class Range
end
class Proc
end
class String
  def %(format)
  end
  def *(integer)
  end
  def +(other_str)
  end
  def <<(int_or_obj)
  end
  def <=>(other_str)
  end
  def ==(other_str)
  end
  def ===(other_str)
  end
  def =~(obj_or_reg)
  end
  def [](*args)
  end
  def []=(*args, val)
  end
  def ascii_only?
  end
  def bytes
  end
  def bytesize
  end
  def capitalize
  end
  def capitalize!
  end
  def casecmp(other_str)
  end
  def center(integer, padstr)
  end
  def chars
  end
  def chomp(separator=$/)
  end
  def chomp!(separator=$/)
  end
  def chop
  end
  def chop!
  end
  def chr
  end
  def clear
  end
  def codepoints
  end
  def concat(int_or_obj)
  end
  def count(other_str, *more_strs)
  end
  def crypt(other_str)
  end
  def delete(other_str, *more_strs)
  end
  def delete!(other_str, *more_strs)
  end
  def downcase
  end
  def downcase!
  end
  def dump
  end
  def each_byte
  end
  def each_char
  end
  def each_codepoint
  end
  def each_line(separator = $/)
  end
  def empty?
  end
  def encode(*args)
  end
  def encode!(*args)
  end
  def encoding
  end
  def end_with?(other_str, *more_strs)
  end
  def eql?(other)
  end
  def force_encoding(encoding)
  end
  def getbyte(index)
  end
  def gsub(pattern, *other_args)
  end
  def gsub!(pattern, *other_args)
  end
  def hash
  end
  def hex
  end
  def include?(other_str)
  end
  def index(substring_or_reg, offset=0)
  end
  def insert(index, other_str)
  end
  def inspect
  end
  def intern
  end
  def length
  end
  def lines(separator = $/)
  end
  def ljust(integer, padstr='')
  end
  def lstrip
  end
  def lstrip!
  end
  def match(pattern, pos=0)
  end
  def next
  end
  def next!
  end
  def oct
  end
  def ord
  end
  def partition(sep_or_regex)
  end
  def replace(other_str)
  end
  def reverse
  end
  def reverse!
  end
  def rindex(substring_or_regex, pos=0)
  end
  def rjust(integer, padstr=' ')
  end
  def rpartition(sep_or_regex)
  end
  def rstrip
  end
  def rstrip!
  end
  def scan(pattern)
  end
  def setbyte(index, int)
  end
  def size
  end
  def slice(*args)
  end
  def slice!(*args)
  end
  def split(pattern=$;, limit=nil)
  end
  def squeeze(*other_strs)
  end
  def squeeze!(*other_strs)
  end
  def start_with?(prefix, *prefixes)
  end
  def strip
  end
  def strip!
  end
  def sub(pattern, *rest)
  end
  def sub!(pattern, *rest)
  end
  def succ
  end
  def succ!
  end
  def sum(n=16)
  end
  def swapcase
  end
  def swapcase!
  end
  def to_c
  end
  def to_f
  end
  def to_i(base=10)
  end
  def to_r
  end
  def to_s
  end
  def to_str
  end
  def to_sym
  end
  def tr(from_str, to_str)
  end
  def tr!(from_str, to_str)
  end
  def tr_s(from_str, to_str)
  end
  def tr_s!(from_str, to_str)
  end
  def unpack(format)
  end
  def upcase
  end
  def upcase!
  end
  def upto(other_str, exclusive = false)
  end
  def valid_encoding?
  end
end
class Symbol
end
class Regexp
end
class Numeric
  include Comparable
  def %(other)
  end
  def +@
  end
  def -@
  end
  def <=>(other)
  end
  def abs
  end
  def abs2
  end
  def arg
  end
  def angle
    arg
  end
  def ceil
  end
  def coerce(num)
  end
  def conj
  end
  def conjugate
    conj
  end
  def denominator
  end
  def div(numeric)
  end
  def divmod(numeric)
  end
  def eql?(numeric)
  end
  def fdiv(numeric)
  end
  def floor
  end
  def i
  end
  def imag
  end
  def imaginary
  end
  def integer?
  end
  def magnitude
    abs
  end
  def modulo(numeric)
  end
  def nonzero?
  end
  def numerator
  end
  def phase
    arg
  end
  def polar
  end
  def pretty_print
  end
  def pretty_print_cycle
  end
  def quo(numeric)
  end
  def real
  end
  def real?
  end
  def rect
  end
  def rectangular
    rect
  end
  def remainder(numeric)
  end
  def round(numdigits=0)
  end
  def singleton_method_added(p1)
    raise TypeError.new
  end
  def step(limit, step=1)
  end
  def to_c
  end
  def to_int
  end
  def truncate
  end
  def zero?
  end
  
end
class Integer < Numeric
  def ceil
  end
  def chr
  end
  def denominator
  end
  def downto(int)
  end
  def even?
  end
  def floor
  end
  def gcd(int)
  end
  def gcdlcm(int)
  end
  def integer?
  end
  def lcm(int)
  end
  def next
  end
  def numerator
  end
  def odd?
  end
  def ord
  end
  def pred
  end
  def rationalize
  end
  def round(digits=0)
  end
  def succ
  end
  def times
  end
  def to_i
  end
  def to_int
  end
  def to_r
  end
  def truncate
  end
  def upto(max)
  end
end
class Fixnum < Integer
  def %(num)
  end
  def &(num)
  end
  def *(num)
  end
  def **(num)
  end
  def +(num)
  end
  def -(num)
  end
  def -@
  end
  def /(num)
  end
  def <(num)
  end
  def <<(amt)
  end
  def <=(num)
  end
  def <=>(num)
  end
  def ==(num)
  end
  def ===(num)
  end
  def >(num)
  end
  def >=(num)
  end
  def >>(num)
  end
  def [](bit)
  end
  def ^(num)
  end
  def abs
  end
  def div(other)
  end
  def divmod(other)
  end
  def even?
  end
  def fdiv(num)
  end
  def magnitude
  end
  def modulo(num)
  end
  def odd?
  end
  def size
  end
  def succ
  end
  def to_f
  end
  def to_s
  end
  def zero?
  end
  def |(num)
  end
  def ~
  end
end
class Bignum < Integer
  def %(num)
  end
  def &(num)
  end
  def *(num)
  end
  def **(num)
  end
  def +(num)
  end
  def -(num)
  end
  def -@
  end
  def /(num)
  end
  def <(num)
  end
  def <<(amt)
  end
  def <=(num)
  end
  def <=>(num)
  end
  def ==(num)
  end
  def ===(num)
  end
  def >(num)
  end
  def >=(num)
  end
  def >>(num)
  end
  def [](bit)
  end
  def ^(num)
  end
  def abs
  end
  def coerce(numeric)
  end
  def div(other)
  end
  def divmod(other)
  end
  def eql?(other)
  end
  def even?
  end
  def fdiv(num)
  end
  def magnitude
  end
  def modulo(num)
  end
  def odd?
  end
  def remainder
  end
  def size
  end
  def to_f
  end
  def to_s
  end
  def |(num)
  end
  def ~
  end
end
class Float < Numeric
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

module Errno
end
class Errno::NOERROR < SystemCallError
end
class Errno::EPERM < SystemCallError
end
class Errno::ENOENT < SystemCallError
end
class Errno::ESRCH < SystemCallError
end
class Errno::EINTR < SystemCallError
end
class Errno::EIO < SystemCallError
end
class Errno::ENXIO < SystemCallError
end
class Errno::E2BIG < SystemCallError
end
class Errno::ENOEXEC < SystemCallError
end
class Errno::EBADF < SystemCallError
end
class Errno::ECHILD < SystemCallError
end
class Errno::EAGAIN < SystemCallError
end
class Errno::ENOMEM < SystemCallError
end
class Errno::EACCES < SystemCallError
end
class Errno::EFAULT < SystemCallError
end
class Errno::ENOTBLK < SystemCallError
end
class Errno::EBUSY < SystemCallError
end
class Errno::EEXIST < SystemCallError
end
class Errno::EXDEV < SystemCallError
end
class Errno::ENODEV < SystemCallError
end
class Errno::ENOTDIR < SystemCallError
end
class Errno::EISDIR < SystemCallError
end
class Errno::EINVAL < SystemCallError
end
class Errno::ENFILE < SystemCallError
end
class Errno::EMFILE < SystemCallError
end
class Errno::ENOTTY < SystemCallError
end
class Errno::ETXTBSY < SystemCallError
end
class Errno::EFBIG < SystemCallError
end
class Errno::ENOSPC < SystemCallError
end
class Errno::ESPIPE < SystemCallError
end
class Errno::EROFS < SystemCallError
end
class Errno::EMLINK < SystemCallError
end
class Errno::EPIPE < SystemCallError
end
class Errno::EDOM < SystemCallError
end
class Errno::ERANGE < SystemCallError
end
class Errno::EDEADLK < SystemCallError
end
class Errno::ENAMETOOLONG < SystemCallError
end
class Errno::ENOLCK < SystemCallError
end
class Errno::ENOSYS < SystemCallError
end
class Errno::ENOTEMPTY < SystemCallError
end
class Errno::ELOOP < SystemCallError
end
class Errno::ENOMSG < SystemCallError
end
class Errno::EIDRM < SystemCallError
end
class Errno::ENOSTR < SystemCallError
end
class Errno::ENODATA < SystemCallError
end
class Errno::ETIME < SystemCallError
end
class Errno::ENOSR < SystemCallError
end
class Errno::EREMOTE < SystemCallError
end
class Errno::ENOLINK < SystemCallError
end
class Errno::EPROTO < SystemCallError
end
class Errno::EMULTIHOP < SystemCallError
end
class Errno::EBADMSG < SystemCallError
end
class Errno::EOVERFLOW < SystemCallError
end
class Errno::EILSEQ < SystemCallError
end
class Errno::EUSERS < SystemCallError
end
class Errno::ENOTSOCK < SystemCallError
end
class Errno::EDESTADDRREQ < SystemCallError
end
class Errno::EMSGSIZE < SystemCallError
end
class Errno::EPROTOTYPE < SystemCallError
end
class Errno::ENOPROTOOPT < SystemCallError
end
class Errno::EPROTONOSUPPORT < SystemCallError
end
class Errno::ESOCKTNOSUPPORT < SystemCallError
end
class Errno::EOPNOTSUPP < SystemCallError
end
class Errno::EPFNOSUPPORT < SystemCallError
end
class Errno::EAFNOSUPPORT < SystemCallError
end
class Errno::EADDRINUSE < SystemCallError
end
class Errno::EADDRNOTAVAIL < SystemCallError
end
class Errno::ENETDOWN < SystemCallError
end
class Errno::ENETUNREACH < SystemCallError
end
class Errno::ENETRESET < SystemCallError
end
class Errno::ECONNABORTED < SystemCallError
end
class Errno::ECONNRESET < SystemCallError
end
class Errno::ENOBUFS < SystemCallError
end
class Errno::EISCONN < SystemCallError
end
class Errno::ENOTCONN < SystemCallError
end
class Errno::ESHUTDOWN < SystemCallError
end
class Errno::ETOOMANYREFS < SystemCallError
end
class Errno::ETIMEDOUT < SystemCallError
end
class Errno::ECONNREFUSED < SystemCallError
end
class Errno::EHOSTDOWN < SystemCallError
end
class Errno::EHOSTUNREACH < SystemCallError
end
class Errno::EALREADY < SystemCallError
end
class Errno::EINPROGRESS < SystemCallError
end
class Errno::ESTALE < SystemCallError
end
class Errno::EDQUOT < SystemCallError
end
class Errno::ECANCELED < SystemCallError
end
class Errno::EAUTH < SystemCallError
end
class Errno::EBADRPC < SystemCallError
end
class Errno::EFTYPE < SystemCallError
end
class Errno::ENEEDAUTH < SystemCallError
end
class Errno::ENOATTR < SystemCallError
end
class Errno::ENOTSUP < SystemCallError
end
class Errno::EPROCLIM < SystemCallError
end
class Errno::EPROCUNAVAIL < SystemCallError
end
class Errno::EPROGMISMATCH < SystemCallError
end
class Errno::EPROGUNAVAIL < SystemCallError
end
class Errno::ERPCMISMATCH < SystemCallError
end

class << self
  def private
  end
  def public
  end
end


# ARGV: [String]
ARGV = []
# DATA: File | NilClass
DATA = nil
