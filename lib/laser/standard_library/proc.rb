class Proc
  # pure: true
  # builtin: true
  # raises: never
  def self.new(&blk)
  end

  def call(*args)
  end
  alias yield call
  alias [] call
  # pure: true
  # raises: never
  def to_proc
    self
  end
  
  # pure: true
  # builtin: true
  # raises: never
  def lexical_self=(val)
  end
end