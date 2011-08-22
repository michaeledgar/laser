module Kernel
  # pure: true
  # builtin: true
  # raises: never
  # returns: Boolean
  def eql?(other)
  end
  # pure: true
  # builtin: true
  # raises: never
  # returns: Boolean
  def equal?(other)
  end
  # builtin: true
  # klass: Module
  # raises: never
  def is_a?(klass)
  end
  alias kind_of? is_a?
  # pure: true
  # raises: never
  # builtin: true
  def singleton_class
  end
  # pure: true
  # raises: never
  # builtin: true
  # returns: Class=
  def class
  end
  # pure: true
  # raises: never
  def inspect
  end
  # builtin: true
  def instance_variable_get(name)
  end
  # builtin: true
  def instance_variable_defined?(name)
  end
  # builtin: true
  def instance_variable_set(name, val)
  end
 private

  
  # raises: never
  # returns: Symbol= | NilClass=
  # builtin: true
  # special: true
  def __method__
  end
  alias __callee__ __method__

  # raises: never
  # returns: Binding=
  # builtin: true
  # special: true
  def binding
  end

  # raises: never
  # returns: Array=
  # builtin: true
  # special: true
  def caller
  end

  # raises: never
  # returns: Continuation=
  # builtin: true
  # special: true
  def callcc
  end
 
  # yield_usage: required
  def proc
    unless block_given?
      raise ArgumentError.new('tried to create Proc object without a block')
    end
    Proc.new
  end

  # raises: never
  def p(*args)
    args
  end
  def eval(string, bndg = nil, filename = nil, lineno = nil)
  end
  def autoload(sym, path)
  end
  alias fail raise
  # predictable: false
  # returns: String=
  # raises: maybe
  def gets(opt_arg_1 = :__unset__, opt_arg_2 = :__unset__)
  end
  # predictable: false
  def puts(*to_put)
  end
  # returns: Boolean
  # raises: never
  def block_given?
  end
  alias iterator? block_given?
  # builtin: true
  # raises: never
  # pure: false
  # predictable: false
  # overload: () -> Float
  # overload: Fixnum= -> Fixnum= | Bignum=
  # overload: Bignum= -> Fixnum= | Bignum=
  def rand(n=nil)
  end
end