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

require 'integer'
require 'float'