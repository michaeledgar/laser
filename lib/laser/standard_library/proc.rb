class Proc
  # pure: true
  # builtin: true
  # raises: never
  # yield_usage: optional
  def self.new(&blk)
  end

  # builtin: true
  def call(*args)
  end
  alias yield call
  alias [] call

  def ===(other)
    call(other)
  end

  # pure: true
  # raises: never
  def to_proc
    self
  end
  
  # pure: true
  # builtin: true
  # raises: never
  # returns: empty
  def lexical_self=(val)
  end
end
