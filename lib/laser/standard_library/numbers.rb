class Numeric
  include Comparable
  # pure: true
  # builtin: true
  def %(other)
  end
  # pure: true
  # builtin: true
  def +@
  end
  # pure: true
  # builtin: true
  def -@
  end
  # pure: true
  # builtin: true
  def <=>(other)
  end
  # pure: true
  # builtin: true
  def abs
  end
  # pure: true
  # builtin: true
  def abs2
  end
  # pure: true
  # builtin: true
  def arg
  end
  # pure: true
  # builtin: true
  def angle
    arg
  end
  # pure: true
  # builtin: true
  def ceil
  end
  # pure: true
  # builtin: true
  def coerce(num)
  end
  # pure: true
  # builtin: true
  def conj
  end
  # pure: true
  # builtin: true
  def conjugate
    conj
  end
  # pure: true
  # builtin: true
  def denominator
  end
  # pure: true
  # builtin: true
  def div(numeric)
  end
  # pure: true
  # builtin: true
  def divmod(numeric)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  def eql?(numeric)
  end
  # pure: true
  # builtin: true
  def fdiv(numeric)
  end
  # pure: true
  # builtin: true
  def floor
  end
  # pure: true
  # builtin: true
  def i
  end
  # pure: true
  # builtin: true
  def imag
  end
  # pure: true
  # builtin: true
  def imaginary
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  def integer?
  end
  # pure: true
  # builtin: true
  def magnitude
    abs
  end
  # pure: true
  # builtin: true
  def modulo(numeric)
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  def nonzero?
  end
  # pure: true
  # builtin: true
  def numerator
  end
  # pure: true
  # builtin: true
  def phase
    arg
  end
  # pure: true
  # builtin: true
  def polar
  end
  # pure: true
  # builtin: true
  def pretty_print
  end
  # pure: true
  # builtin: true
  def pretty_print_cycle
  end
  # pure: true
  # builtin: true
  def quo(numeric)
  end
  # pure: true
  # builtin: true
  def real
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  def real?
  end
  # pure: true
  # builtin: true
  def rect
  end
  # pure: true
  # builtin: true
  def rectangular
    rect
  end
  # pure: true
  # builtin: true
  def remainder(numeric)
  end
  # pure: true
  # builtin: true
  def round(numdigits=0)
  end
  # pure: true
  # builtin: true
  # raise: always
  def singleton_method_added(p1)
    raise TypeError.new
  end
  # pure: true
  # builtin: true
  # yield_usage: optional
  def step(limit, step=1)
  end
  # pure: true
  # builtin: true
  def to_c
  end
  # pure: true
  # builtin: true
  def to_int
  end
  # pure: true
  # builtin: true
  def truncate
  end
  # pure: true
  # builtin: true
  # returns: Boolean
  def zero?
  end
end

require 'integer'
require 'float'
require 'complex'