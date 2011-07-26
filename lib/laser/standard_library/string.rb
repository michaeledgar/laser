class String
  include Comparable
  # pure: true
  # builtin: true
  # returns: String=
  def %(format)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # integer: Fixnum= | Bignum= | Float=
  # raises: never
  def *(integer)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # other_str: String=
  # raises: never
  def +(other_str)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # int_or_obj: Fixnum= | Bignum= | String=
  # raises: never
  def <<(int_or_obj)
  end
  # pure: true
  # builtin: true
  # returns: NilClass | Fixnum=
  # raises: never
  def <=>(other_str)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  # raises: never
  def ==(other_str)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  # raises: never
  def ===(other_str)
  end
  # pure: true
  # builtin: true
  def =~(obj_or_reg)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def [](*args)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def []=(*args, val)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  # raises: never
  def ascii_only?
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  # raises: never
  def bytes
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  # raises: never
  def bytesize
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def capitalize
  end
  # pure: true
  # builtin: true
  # returns: NilClass | String=
  # raises: never
  def capitalize!
  end
  # pure: true
  # builtin: true
  # overload: String= -> Fixnum=
  # overload: BasicObject -> NilClass
  # raises: never
  def casecmp(other_str)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # integer: Fixnum= | Bignum= | Float=
  # raises: never
  def center(integer, padstr=' ')
  end
  # pure: true
  # builtin: true
  # returns: String=
  # yield_usage: optional
  # raises: never
  def chars
  end
  # pure: true
  # builtin: true
  # returns: String=
  # separator: String=
  # raises: never
  def chomp(separator=$/)
  end
  # pure: true
  # builtin: true
  # separator: String=
  # returns: String= | NilCLass
  # raises: never
  def chomp!(separator=$/)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def chop
  end
  # pure: true
  # builtin: true
  # raises: never
  def chop!
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def chr
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def clear
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  # raises: never
  def codepoints
  end
  # pure: true
  # builtin: true
  # returns: String=
  # int_or_obj: Fixnum= | Bignum= | String=
  # raises: never
  def concat(int_or_obj)
  end
  # pure: true
  # builtin: true
  # raises: never
  # other_str: String=
  def count(other_str, *more_strs)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  # other_str: String=
  def crypt(other_str)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  # other_str: String=
  def delete(other_str, *more_strs)
  end
  # pure: true
  # builtin: true
  # returns: String= | NilClass
  # raises: never
  # other_str: String=
  def delete!(other_str, *more_strs)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def downcase
  end
  # pure: true
  # builtin: true
  # raises: never
  # returns: String= | NilClass
  def downcase!
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def dump
  end

  alias each_byte bytes
  alias each_char chars
  alias each_codepoint codepoints
  alias each_line lines
  # pure: true
  # builtin: true
  # returns: Boolean
  # raises: never
  def empty?
  end
  # pure: true
  # builtin: true
  def encode(*args)
  end
  # pure: true
  # builtin: true
  def encode!(*args)
  end
  # pure: true
  # builtin: true
  # raises: never
  # returns: Encoding
  def encoding
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  # other_str: String=
  # raises: never
  def end_with?(other_str, *more_strs)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  # raises: never
  def eql?(other)
  end
  # pure: true
  # builtin: true
  def force_encoding(encoding)
  end
  # pure: true
  # builtin: true
  # index: Fixnum= | Float=
  # returns: Fixnum=
  # raises: IndexError=
  def getbyte(index)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # yield_usage: optional
  # pattern: Regexp= | String=
  # maybe_arg: String= | Hash=
  # raises: never
  def gsub(pattern, maybe_arg=nil)
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  # returns: String= | NilClass=
  # pattern: Regexp= | String=
  # maybe_arg: String= | Hash=
  # raises: never
  def gsub!(pattern, maybe_arg=nil)
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  # raises: never
  def hash
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  # raises: never
  def hex
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  # raises: never
  # other_str: String=
  def include?(other_str)
  end
  # pure: true
  # builtin: true
  # substring_or_reg: String= | Regexp=
  # offset: Fixnum= | Bignum= | Float=
  # raises: never
  # returns: Fixnum= | Bignum= | NilClass=
  def index(substring_or_reg, offset=0)
  end
  # pure: true
  # builtin: true
  # index: Fixnum= | Bignum=
  # other_str: String=
  # raises: IndexError=
  def insert(index, other_str)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def inspect
  end
  # pure: true
  # builtin: true
  # returns: Symbol
  # raises: never
  def intern
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  # raises: never
  def length
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  # lines: String=
  # raises: never
  def lines(separator = $/)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # amt: Fixnum= | Bignum=
  # padstr: String
  # raises: never
  def ljust(amt, padstr='')
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def lstrip
  end
  # pure: true
  # builtin: true
  # returns: String= | NilClass
  # raises: never
  def lstrip!
  end
  # pure: true
  # builtin: true
  # raises: IndexError=
  # pattern: String= | Regexp=
  # pos: Fixnum= | Bignum=
  def match(pattern, pos=0)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def next
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def next!
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  # raises: never
  def oct
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  # raises: never
  def ord
  end
  # pure: true
  # builtin: true
  # returns: Array=
  # raises: never
  # sep_or_regex: String= | Regexp=
  def partition(sep_or_regex)
  end
  # pure: true
  # builtin: true
  # raises: never
  # other_str: String=
  # returns: String
  def replace(other_str)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def reverse
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def reverse!
  end
  # pure: true
  # builtin: true
  # substring_or_reg: String= | Regexp=
  # offset: Fixnum= | Bignum= | Float=
  # raises: never
  # returns: Fixnum= | Bignum= | NilClass=
  def rindex(substring_or_regex, pos=0)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # amt: Fixnum= | Bignum=
  # padstr: String
  # raises: never
  def rjust(integer, padstr=' ')
  end
  # pure: true
  # builtin: true
  # returns: Array=
  # raises: never
  # sep_or_regex: String= | Regexp=
  def rpartition(sep_or_regex)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def rstrip
  end
  # pure: true
  # builtin: true
  # returns: String= | NilClass
  # raises: never
  def rstrip!
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  # pattern: Regexp= | String=
  # returns: Array=
  # raises: never
  def scan(pattern)
  end
  # pure: true
  # builtin: true
  # index: Fixnum= | Float=
  # returns: Fixnum=
  # raises: IndexError=
  # int: Fixnum= | Float=
  def setbyte(index, int)
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  # raises: never
  def size
  end
  # pure: true
  # builtin: true
  # returns: String=
  def slice(*args)
  end
  # pure: true
  # builtin: true
  def slice!(*args)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  # pattern: String= | Regexp=
  # limit: Fixnum=
  # raises: never
  def split(pattern=$;, limit=nil)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def squeeze(*other_strs)
  end
  # pure: true
  # builtin: true
  # returns: String= | NilClass
  # raises: never
  def squeeze!(*other_strs)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  # other_str: String=
  # raises: never
  def start_with?(prefix, *prefixes)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def strip
  end
  # pure: true
  # builtin: true
  # returns: String= | NilClass
  # raises: never
  def strip!
  end
  # pure: true
  # builtin: true
  # returns: String=
  # yield_usage: optional
  # pattern: String= | Regexp=
  def sub(pattern, *rest)
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  # returns: String= | NilClass
  # pattern: String= | Regexp=
  def sub!(pattern, *rest)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def succ
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def succ!
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  # n: Fixnum=
  # raises: never
  def sum(n=16)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def swapcase
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def swapcase!
  end
  # pure: true
  # builtin: true
  # returns: Complex
  # raises: never
  def to_c
  end
  # pure: true
  # builtin: true
  # returns: Float
  # raises: never
  def to_f
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  # base: Fixnum=
  # raises: ArgumentError=
  def to_i(base=10)
  end
  # pure: true
  # builtin: true
  # raises: never
  def to_r
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def to_s
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def to_str
  end
  # pure: true
  # builtin: true
  # returns: Symbol
  # raises: never
  def to_sym
  end
  # pure: true
  # builtin: true
  # returns: String=
  # from_str: String=
  # to_str: String=
  # raises: never
  def tr(from_str, to_str)
  end
  # pure: true
  # builtin: true
  # from_str: String=
  # to_str: String=
  # raises: never
  # returns: String= | NilClass=
  def tr!(from_str, to_str)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # from_str: String=
  # to_str: String=
  # raises: never
  def tr_s(from_str, to_str)
  end
  # pure: true
  # builtin: true
  # from_str: String=
  # to_str: String=
  # raises: never
  # returns: String= | NilClass=
  def tr_s!(from_str, to_str)
  end
  # pure: true
  # builtin: true
  # returns: Array
  # raises: ArgumentError=
  # format: String=
  def unpack(format)
  end
  # pure: true
  # builtin: true
  # returns: String=
  # raises: never
  def upcase
  end
  # pure: true
  # builtin: true
  # raises: never
  # returns: String= | NilCLass=
  def upcase!
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  # other_str: String=
  # raises: never
  def upto(other_str, exclusive = false)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  # raises: never
  def valid_encoding?
  end
end
