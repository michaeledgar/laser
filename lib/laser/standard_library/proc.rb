class Proc
  def call(*args)
  end
  alias yield call
  alias [] call
  # pure: true
  def to_proc
    self
  end
  
  # pure: true
  # builtin: true
  def lexical_self=(val)
  end
end