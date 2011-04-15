class Numeric
  include Comparable
  # pure: true
  def %(other)
  end
  # pure: true
  def +@
  end
  # pure: true
  def -@
  end
  # pure: true
  def <=>(other)
  end
  # pure: true
  def abs
  end
  # pure: true
  def abs2
  end
  # pure: true
  def arg
  end
  # pure: true
  def angle
    arg
  end
  # pure: true
  def ceil
  end
  # pure: true
  def coerce(num)
  end
  # pure: true
  def conj
  end
  # pure: true
  def conjugate
    conj
  end
  # pure: true
  def denominator
  end
  # pure: true
  def div(numeric)
  end
  # pure: true
  def divmod(numeric)
  end
  # pure: true
  def eql?(numeric)
  end
  # pure: true
  def fdiv(numeric)
  end
  # pure: true
  def floor
  end
  # pure: true
  def i
  end
  # pure: true
  def imag
  end
  # pure: true
  def imaginary
  end
  # pure: true
  def integer?
  end
  # pure: true
  def magnitude
    abs
  end
  # pure: true
  def modulo(numeric)
  end
  # pure: true
  def nonzero?
  end
  # pure: true
  def numerator
  end
  # pure: true
  def phase
    arg
  end
  # pure: true
  def polar
  end
  # pure: true
  def pretty_print
  end
  # pure: true
  def pretty_print_cycle
  end
  # pure: true
  def quo(numeric)
  end
  # pure: true
  def real
  end
  # pure: true
  def real?
  end
  # pure: true
  def rect
  end
  # pure: true
  def rectangular
    rect
  end
  # pure: true
  def remainder(numeric)
  end
  # pure: true
  def round(numdigits=0)
  end
  # pure: true
  def singleton_method_added(p1)
    raise TypeError.new
  end
  # pure: true
  def step(limit, step=1)
  end
  # pure: true
  def to_c
  end
  # pure: true
  def to_int
  end
  # pure: true
  def truncate
  end
  # pure: true
  def zero?
  end
end

require 'integer'
require 'float'