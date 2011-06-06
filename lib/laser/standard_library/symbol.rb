class Symbol
  # builtin: true
  # pure: true
  # returns: Fixnum= | NilClass
  def <=>(other)
  end
  # builtin: true
  # pure: true
  # returns: Boolean
  def ==(other)
  end
  # builtin: true
  # pure: true
  # returns: Boolean
  def ===(other)
  end
  # builtin: true
  # pure: true
  # returns: Fixnum= | Bignum= | NilClass
  def =~(other)
  end
  # builtin: true
  # pure: true
  def [](arg1, arg2 = :__unset__)
  end
  # builtin: true
  # pure: true
  # returns: String=
  def capitalize
  end
  # builtin: true
  # pure: true
  # returns: Fixnum= | NilClass
  def casecmp(other)
  end
  # builtin: true
  # pure: true
  # returns: String=
  def downcase
  end
  # builtin: true
  # pure: true
  # returns: Boolean
  def empty?
  end
  # builtin: true
  # pure: true
  # returns: Encoding
  def encoding
  end
  # builtin: true
  # pure: true
  # returns: String=
  def id2name
  end
  # builtin: true
  # pure: true
  # returns: String=
  def inspect
  end
  # builtin: true
  # pure: true
  # returns: Symbol=
  def intern
  end
  # builtin: true
  # pure: true
  # returns: Fixnum= | Bignum=
  def length
  end
  # builtin: true
  # pure: true
  def match(other)
  end
  # builtin: true
  # pure: true
  # returns: String=
  def next
  end
  # builtin: true
  # pure: true
  # returns: Fixnum= | Bignum=
  def size
  end
  # builtin: true
  # pure: true
  def slice(arg1, arg2 = :__unset__)
  end
  # builtin: true
  # pure: true
  # returns: String=
  def succ
  end
  # builtin: true
  # pure: true
  # returns: String=
  def swapcase
  end
  # pure: true
  def to_proc
    proc { |x| x.send(self) }
  end
  # builtin: true
  # pure: true
  # returns: String=
  def to_s
  end
  # builtin: true
  # pure: true
  # returns: Symbol=
  def to_sym
  end
  # builtin: true
  # pure: true
  # returns: String=
  def to_yaml
  end
  # builtin: true
  # pure: true
  # returns: String=
  def upcase
  end
end
