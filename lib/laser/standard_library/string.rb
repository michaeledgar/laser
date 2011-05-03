class String
  include Comparable
  # pure: true
  # builtin: true
  def %(format)
  end
  # pure: true
  # builtin: true
  def *(integer)
  end
  # pure: true
  # builtin: true
  def +(other_str)
  end
  # pure: true
  # builtin: true
  def <<(int_or_obj)
  end
  # pure: true
  # builtin: true
  def <=>(other_str)
  end
  # pure: true
  # builtin: true
  def ==(other_str)
  end
  # pure: true
  # builtin: true
  def ===(other_str)
  end
  # pure: true
  # builtin: true
  def =~(obj_or_reg)
  end
  # pure: true
  # builtin: true
  def [](*args)
  end
  # pure: true
  # builtin: true
  def []=(*args, val)
  end
  # pure: true
  # builtin: true
  def ascii_only?
  end
  # pure: true
  # builtin: true
  def bytes
  end
  # pure: true
  # builtin: true
  def bytesize
  end
  # pure: true
  # builtin: true
  def capitalize
  end
  # pure: true
  # builtin: true
  def capitalize!
  end
  # pure: true
  # builtin: true
  def casecmp(other_str)
  end
  # pure: true
  # builtin: true
  def center(integer, padstr)
  end
  # pure: true
  # builtin: true
  def chars
  end
  # pure: true
  # builtin: true
  def chomp(separator=$/)
  end
  # pure: true
  # builtin: true
  def chomp!(separator=$/)
  end
  # pure: true
  # builtin: true
  def chop
  end
  # pure: true
  # builtin: true
  def chop!
  end
  # pure: true
  # builtin: true
  def chr
  end
  # pure: true
  # builtin: true
  def clear
  end
  # pure: true
  # builtin: true
  def codepoints
  end
  # pure: true
  # builtin: true
  def concat(int_or_obj)
  end
  # pure: true
  # builtin: true
  def count(other_str, *more_strs)
  end
  # pure: true
  # builtin: true
  def crypt(other_str)
  end
  # pure: true
  # builtin: true
  def delete(other_str, *more_strs)
  end
  # pure: true
  # builtin: true
  def delete!(other_str, *more_strs)
  end
  # pure: true
  # builtin: true
  def downcase
  end
  # pure: true
  # builtin: true
  def downcase!
  end
  # pure: true
  # builtin: true
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
  def end_with?(other_str, *more_strs)
  end
  # pure: true
  # builtin: true
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
  def gsub(pattern, *other_args)
  end
  # pure: true
  # builtin: true
  def gsub!(pattern, *other_args)
  end
  # pure: true
  # builtin: true
  def hash
  end
  # pure: true
  # builtin: true
  def hex
  end
  # pure: true
  # builtin: true
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
  def inspect
  end
  # pure: true
  # builtin: true
  def intern
  end
  # pure: true
  # builtin: true
  def length
  end
  # pure: true
  # builtin: true
  def lines(separator = $/)
  end
  # pure: true
  # builtin: true
  def ljust(integer, padstr='')
  end
  # pure: true
  # builtin: true
  def lstrip
  end
  # pure: true
  # builtin: true
  def lstrip!
  end
  # pure: true
  # builtin: true
  def match(pattern, pos=0)
  end
  # pure: true
  # builtin: true
  def next
  end
  # pure: true
  # builtin: true
  def next!
  end
  # pure: true
  # builtin: true
  def oct
  end
  # pure: true
  # builtin: true
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
  def reverse
  end
  # pure: true
  # builtin: true
  def reverse!
  end
  # pure: true
  # builtin: true
  def rindex(substring_or_regex, pos=0)
  end
  # pure: true
  # builtin: true
  def rjust(integer, padstr=' ')
  end
  # pure: true
  # builtin: true
  def rpartition(sep_or_regex)
  end
  # pure: true
  # builtin: true
  def rstrip
  end
  # pure: true
  # builtin: true
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
  def size
  end
  # pure: true
  # builtin: true
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
  def squeeze(*other_strs)
  end
  # pure: true
  # builtin: true
  def squeeze!(*other_strs)
  end
  # pure: true
  # builtin: true
  def start_with?(prefix, *prefixes)
  end
  # pure: true
  # builtin: true
  def strip
  end
  # pure: true
  # builtin: true
  def strip!
  end
  # pure: true
  # builtin: true
  def sub(pattern, *rest)
  end
  # pure: true
  # builtin: true
  def sub!(pattern, *rest)
  end
  # pure: true
  # builtin: true
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
  def swapcase
  end
  # pure: true
  # builtin: true
  def swapcase!
  end
  # pure: true
  # builtin: true
  def to_c
  end
  # pure: true
  # builtin: true
  def to_f
  end
  # pure: true
  # builtin: true
  def to_i(base=10)
  end
  # pure: true
  # builtin: true
  def to_r
  end
  # pure: true
  # builtin: true
  def to_s
  end
  # pure: true
  # builtin: true
  def to_str
  end
  # pure: true
  # builtin: true
  def to_sym
  end
  # pure: true
  # builtin: true
  def tr(from_str, to_str)
  end
  # pure: true
  # builtin: true
  def tr!(from_str, to_str)
  end
  # pure: true
  # builtin: true
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
  def valid_encoding?
  end
end