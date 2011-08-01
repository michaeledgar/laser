class Array
  # pure: true
  # builtin: true
  # returns: Array=
  def self.[](*args)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def &(other_ary)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def |(other_ary)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def *(int_or_str)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def +(other_ary)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def -(other_ary)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def <<(obj)
  end
  # pure: true
  # builtin: true
  def <=>(other_ary)
  end
  # pure: true
  # builtin: true
  def ==(other_ary)
  end
  # pure: true
  # builtin: true
  def [](*args)
  end
  # pure: true
  # builtin: true
  def []=(*args)
  end
  # pure: true
  # builtin: true
  def assoc(obj)
  end
  # pure: true
  # builtin: true
  def at(index)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def clear
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def collect
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def collect!
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def combination(n)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def compact
  end
  # pure: true
  # builtin: true
  def compact!
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def concat(other_ary)
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def count(*args)
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def cycle(n=nil)
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def delete(obj)
  end
  # pure: true
  # builtin: true
  def delete_at(index)
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def delete_if
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def drop(n)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  # yield_usage: optional
  def drop_while
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  # returns: Array=
  def each
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def each_index
  end
  # pure: true
  # builtin: true
  def empty?
  end
  # pure: true
  # builtin: true
  def eql?(other_ary)
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def fetch(*args)
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def fill(*args)
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def find_index(*args)
  end
  # pure: true
  # builtin: true
  def first(*args)
  end
  # pure: true
  # builtin: true
  # returns: Array= | NilClass
  def flatten(*args)
  end
  # pure: true
  # builtin: true
  def flatten!(*args)
  end
  # pure: true
  # builtin: true
  def frozen?
  end
  # pure: true
  # builtin: true
  def hash
  end
  # pure: true
  # builtin: true
  def include?(obj)
  end
  # pure: true
  # builtin: true
  def index(*args)
  end
  # pure: true
  # builtin: true
  def insert(index, *obj)
  end
  # pure: true
  # builtin: true
  def inspect
  end
  # pure: true
  # builtin: true
  def join(sep=$,)
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def keep_if
  end
  # pure: true
  # builtin: true
  def last(*arg)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  # yield_usage: optional
  def map
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def map!
  end
  # pure: true
  # builtin: true
  def pack(template_string)
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def permutation(*arg)
  end
  # pure: true
  # builtin: true
  def pop(*arg)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  # yield_usage: optional
  def product(other_ary, *rest)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def push(obj, *rest)
  end
  # pure: true
  # builtin: true
  def rassoc(obj)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  # yield_usage: optional
  def reject
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def reject!
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def repeated_combination(n)
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def repeated_permutation(n)
  end
  # pure: true
  # builtin: true
  def replace(other_ary)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def reverse
  end
  # pure: true
  # builtin: true
  def reverse!
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def reverse_each
  end
  # pure: true
  # builtin: true
  def rindex(*obj_or_not)
  end
  # pure: true
  # builtin: true
  def rotate(n=1)
  end
  # pure: true
  # builtin: true
  def rotate!(cnt=1)
  end
  # builtin: true
  # predictable: false
  def sample(*n_or_not)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  # yield_usage: optional
  def select
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def select!
  end
  # pure: true
  # builtin: true
  def shift(*n_or_not)
  end
  # builtin: true
  # predictable: false
  # returns: Array=
  def shuffle
  end
  # builtin: true
  # predictable: false
  def shuffle!
  end
  # pure: true
  # raise: false
  # builtin: true
  # returns: Fixnum=
  def size
  end
  alias length size
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
  # returns: Array=
  # yield_usage: optional
  def sort
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def sort!
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def sort_by!
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def take(n)
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def take_while
  end
  # pure: true
  # raise: false
  # builtin: true
  # returns: Array=
  def to_a
  end
  # pure: true
  # raise: false
  # builtin: true
  # returns: Array=
  def to_ary
  end
  # pure: true
  # builtin: true
  # returns: String=
  def to_s
  end
  # pure: true
  # builtin: true
  def transpose
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def uniq
  end
  # pure: true
  # builtin: true
  def uniq!
  end
  # pure: true
  # builtin: true
  # returns: Array=
  def unshift(obj, *objs)
  end
  # pure: true
  # builtin: true
  def values_at(selector, *selectors)
  end
  # pure: true
  # builtin: true
  # returns: Array=
  # yield_usage: optional
  def zip(arg, *args)
  end
end
