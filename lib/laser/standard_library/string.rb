class String
  include Comparable
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