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
  # yield_usage: maybe
  # builtin: true
  # special: true
  # returns: Fixnum= | NilClass=
  def fork
  end

  # raises: never
  # yield_usage: maybe
  # builtin: true
  # special: true
  # returns: Fixnum= | NilClass=
  def fork
  end

  # raises: never
  # builtin: true
  # special: true
  # returns: empty
  def exec(env={}, *parts)
  end

  # raises: never
  # builtin: true
  # returns: NilClass=
  def warn(msg)
  end

  # should benefit from CP seriously!

  # raises: maybe
  # builtin: true
  # returns: Time= | Boolean= | NilClass= | Fixnum=
  def test(cmd, file1, file2=nil)
  end

  # raises: maybe
  # raises: ArgumentError=
  # returns: Proc= | NilClass=
  # builtin: true
  # special: true
  def trap(sig, cmd)
  end

  # raises: never
  # returns: empty
  # builtin: true
  # special: true
  def throw(tag, obj=nil)
  end
  
  # yield_usage: always
  # builtin: true
  # special: true
  def catch(obj=nil)
  end

  # raises: maybe
  # raises: NameError
  # builtin: true
  # returns: Method=
  def method(which)
  end

  # raises: never
  # builtin: true
  # returns: Array=
  def methods
  end

  # raises: never
  # duration: Float= | Fixnum= | Bignum-
  # returns: Fixnum=
  # builtin: true
  # special: true
  def sleep(duration=nil)
  end

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

  def loop
    while true
      yield
    end
  end

  # raises: always
  # raises: SystemExitException
  # builtin: true
  # returns: empty
  def exit(status=true)
  end

  # raises: always
  # builtin: true
  # returns: empty
  def exit!(status=false)
  end

  def abort(msg=nil)
    exit(false)
  end

  # yield_usage: required
  def proc
    unless block_given?
      raise ArgumentError.new('tried to create Proc object without a block')
    end
    Proc.new
  end

  # yield_usage: required
  def lambda
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