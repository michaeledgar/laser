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
  def *(integer)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def +(other_str)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def <<(int_or_obj)
  end
  # pure: true
  # builtin: true
  # returns: NilClass | Fixnum
  def <=>(other_str)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  def ==(other_str)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
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
  def ascii_only?
  end
  # pure: true
  # builtin: true
  def bytes
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  def bytesize
  end
  # pure: true
  # builtin: true
  # returns: String=
  def capitalize
  end
  # pure: true
  # builtin: true
  # returns: NilClass | String=
  def capitalize!
  end
  # pure: true
  # builtin: true
  def casecmp(other_str)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def center(integer, padstr)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def chars
  end
  # pure: true
  # builtin: true
  # returns: String=
  def chomp(separator=$/)
  end
  # pure: true
  # builtin: true
  def chomp!(separator=$/)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def chop
  end
  # pure: true
  # builtin: true
  def chop!
  end
  # pure: true
  # builtin: true
  # returns: String=
  def chr
  end
  # pure: true
  # builtin: true
  # returns: String=
  def clear
  end
  # pure: true
  # builtin: true
  def codepoints
  end
  # pure: true
  # builtin: true
  # returns: String=
  def concat(int_or_obj)
  end
  # pure: true
  # builtin: true
  def count(other_str, *more_strs)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def crypt(other_str)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def delete(other_str, *more_strs)
  end
  # pure: true
  # builtin: true
  def delete!(other_str, *more_strs)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def downcase
  end
  # pure: true
  # builtin: true
  def downcase!
  end
  # pure: true
  # builtin: true
  # returns: String=
  def dump
  end
  # pure: true
  # builtin: true
  def each_byte
  end
  # pure: true
  # builtin: true
  def each_char
  end
  # pure: true
  # builtin: true
  def each_codepoint
  end
  # pure: true
  # builtin: true
  def each_line(separator = $/)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
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
  def encoding
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  def end_with?(other_str, *more_strs)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  def eql?(other)
  end
  # pure: true
  # builtin: true
  def force_encoding(encoding)
  end
  # pure: true
  # builtin: true
  def getbyte(index)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def gsub(pattern, *other_args)
  end
  # pure: true
  # builtin: true
  def gsub!(pattern, *other_args)
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  def hash
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  def hex
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  def include?(other_str)
  end
  # pure: true
  # builtin: true
  def index(substring_or_reg, offset=0)
  end
  # pure: true
  # builtin: true
  def insert(index, other_str)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def inspect
  end
  # pure: true
  # builtin: true
  # returns: Symbol
  def intern
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  def length
  end
  # pure: true
  # builtin: true
  def lines(separator = $/)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def ljust(integer, padstr='')
  end
  # pure: true
  # builtin: true
  # returns: String=
  def lstrip
  end
  # pure: true
  # builtin: true
  # returns: String= | NilClass
  def lstrip!
  end
  # pure: true
  # builtin: true
  def match(pattern, pos=0)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def next
  end
  # pure: true
  # builtin: true
  # returns: String=
  def next!
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  def oct
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  def ord
  end
  # pure: true
  # builtin: true
  def partition(sep_or_regex)
  end
  # pure: true
  # builtin: true
  def replace(other_str)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def reverse
  end
  # pure: true
  # builtin: true
  # returns: String=
  def reverse!
  end
  # pure: true
  # builtin: true
  def rindex(substring_or_regex, pos=0)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def rjust(integer, padstr=' ')
  end
  # pure: true
  # builtin: true
  def rpartition(sep_or_regex)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def rstrip
  end
  # pure: true
  # builtin: true
  # returns: String= | NilClass
  def rstrip!
  end
  # pure: true
  # builtin: true
  def scan(pattern)
  end
  # pure: true
  # builtin: true
  def setbyte(index, int)
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
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
  def split(pattern=$;, limit=nil)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def squeeze(*other_strs)
  end
  # pure: true
  # builtin: true
  # returns: String= | NilClass
  def squeeze!(*other_strs)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  def start_with?(prefix, *prefixes)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def strip
  end
  # pure: true
  # builtin: true
  # returns: String= | NilClass
  def strip!
  end
  # pure: true
  # builtin: true
  # returns: String=
  def sub(pattern, *rest)
  end
  # pure: true
  # builtin: true
  def sub!(pattern, *rest)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def succ
  end
  # pure: true
  # builtin: true
  def succ!
  end
  # pure: true
  # builtin: true
  def sum(n=16)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def swapcase
  end
  # pure: true
  # builtin: true
  # returns: String=
  def swapcase!
  end
  # pure: true
  # builtin: true
  # returns: Complex
  def to_c
  end
  # pure: true
  # builtin: true
  # returns: Float
  def to_f
  end
  # pure: true
  # builtin: true
  # returns: Fixnum= | Bignum=
  def to_i(base=10)
  end
  # pure: true
  # builtin: true
  def to_r
  end
  # pure: true
  # builtin: true
  # returns: String=
  def to_s
  end
  # pure: true
  # builtin: true
  # returns: String=
  def to_str
  end
  # pure: true
  # builtin: true
  # returns: Symbol
  def to_sym
  end
  # pure: true
  # builtin: true
  # returns: String=
  def tr(from_str, to_str)
  end
  # pure: true
  # builtin: true
  def tr!(from_str, to_str)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def tr_s(from_str, to_str)
  end
  # pure: true
  # builtin: true
  def tr_s!(from_str, to_str)
  end
  # pure: true
  # builtin: true
  def unpack(format)
  end
  # pure: true
  # builtin: true
  # returns: String=
  def upcase
  end
  # pure: true
  # builtin: true
  def upcase!
  end
  # pure: true
  # builtin: true
  def upto(other_str, exclusive = false)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  def valid_encoding?
  end
end
