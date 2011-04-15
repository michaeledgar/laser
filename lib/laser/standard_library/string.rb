class String
  include Comparable
  # pure: true
  def %(format)
  end
  # pure: true
  def *(integer)
  end
  # pure: true
  def +(other_str)
  end
  # pure: true
  def <<(int_or_obj)
  end
  # pure: true
  def <=>(other_str)
  end
  # pure: true
  def ==(other_str)
  end
  # pure: true
  def ===(other_str)
  end
  # pure: true
  def =~(obj_or_reg)
  end
  # pure: true
  def [](*args)
  end
  # pure: true
  def []=(*args, val)
  end
  # pure: true
  def ascii_only?
  end
  # pure: true
  def bytes
  end
  # pure: true
  def bytesize
  end
  # pure: true
  def capitalize
  end
  # pure: true
  def capitalize!
  end
  # pure: true
  def casecmp(other_str)
  end
  # pure: true
  def center(integer, padstr)
  end
  # pure: true
  def chars
  end
  # pure: true
  def chomp(separator=$/)
  end
  # pure: true
  def chomp!(separator=$/)
  end
  # pure: true
  def chop
  end
  # pure: true
  def chop!
  end
  # pure: true
  def chr
  end
  # pure: true
  def clear
  end
  # pure: true
  def codepoints
  end
  # pure: true
  def concat(int_or_obj)
  end
  # pure: true
  def count(other_str, *more_strs)
  end
  # pure: true
  def crypt(other_str)
  end
  # pure: true
  def delete(other_str, *more_strs)
  end
  # pure: true
  def delete!(other_str, *more_strs)
  end
  # pure: true
  def downcase
  end
  # pure: true
  def downcase!
  end
  # pure: true
  def dump
  end
  # pure: true
  def each_byte
  end
  # pure: true
  def each_char
  end
  # pure: true
  def each_codepoint
  end
  # pure: true
  def each_line(separator = $/)
  end
  # pure: true
  def empty?
  end
  # pure: true
  def encode(*args)
  end
  # pure: true
  def encode!(*args)
  end
  # pure: true
  def encoding
  end
  # pure: true
  def end_with?(other_str, *more_strs)
  end
  # pure: true
  def eql?(other)
  end
  # pure: true
  def force_encoding(encoding)
  end
  # pure: true
  def getbyte(index)
  end
  # pure: true
  def gsub(pattern, *other_args)
  end
  # pure: true
  def gsub!(pattern, *other_args)
  end
  # pure: true
  def hash
  end
  # pure: true
  def hex
  end
  # pure: true
  def include?(other_str)
  end
  # pure: true
  def index(substring_or_reg, offset=0)
  end
  # pure: true
  def insert(index, other_str)
  end
  # pure: true
  def inspect
  end
  # pure: true
  def intern
  end
  # pure: true
  def length
  end
  # pure: true
  def lines(separator = $/)
  end
  # pure: true
  def ljust(integer, padstr='')
  end
  # pure: true
  def lstrip
  end
  # pure: true
  def lstrip!
  end
  # pure: true
  def match(pattern, pos=0)
  end
  # pure: true
  def next
  end
  # pure: true
  def next!
  end
  # pure: true
  def oct
  end
  # pure: true
  def ord
  end
  # pure: true
  def partition(sep_or_regex)
  end
  # pure: true
  def replace(other_str)
  end
  # pure: true
  def reverse
  end
  # pure: true
  def reverse!
  end
  # pure: true
  def rindex(substring_or_regex, pos=0)
  end
  # pure: true
  def rjust(integer, padstr=' ')
  end
  # pure: true
  def rpartition(sep_or_regex)
  end
  # pure: true
  def rstrip
  end
  # pure: true
  def rstrip!
  end
  # pure: true
  def scan(pattern)
  end
  # pure: true
  def setbyte(index, int)
  end
  # pure: true
  def size
  end
  # pure: true
  def slice(*args)
  end
  # pure: true
  def slice!(*args)
  end
  # pure: true
  def split(pattern=$;, limit=nil)
  end
  # pure: true
  def squeeze(*other_strs)
  end
  # pure: true
  def squeeze!(*other_strs)
  end
  # pure: true
  def start_with?(prefix, *prefixes)
  end
  # pure: true
  def strip
  end
  # pure: true
  def strip!
  end
  # pure: true
  def sub(pattern, *rest)
  end
  # pure: true
  def sub!(pattern, *rest)
  end
  # pure: true
  def succ
  end
  # pure: true
  def succ!
  end
  # pure: true
  def sum(n=16)
  end
  # pure: true
  def swapcase
  end
  # pure: true
  def swapcase!
  end
  # pure: true
  def to_c
  end
  # pure: true
  def to_f
  end
  # pure: true
  def to_i(base=10)
  end
  # pure: true
  def to_r
  end
  # pure: true
  def to_s
  end
  # pure: true
  def to_str
  end
  # pure: true
  def to_sym
  end
  # pure: true
  def tr(from_str, to_str)
  end
  # pure: true
  def tr!(from_str, to_str)
  end
  # pure: true
  def tr_s(from_str, to_str)
  end
  # pure: true
  def tr_s!(from_str, to_str)
  end
  # pure: true
  def unpack(format)
  end
  # pure: true
  def upcase
  end
  # pure: true
  def upcase!
  end
  # pure: true
  def upto(other_str, exclusive = false)
  end
  # pure: true
  def valid_encoding?
  end
end