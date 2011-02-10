RUBY_VERSION = '1.9.2'
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
end
class Symbol
end
class Regexp
end
class Numeric
  include Comparable
end
class Integer < Numeric
end
class Fixnum < Integer
end
class Bignum < Integer
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
