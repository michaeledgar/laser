class BasicObject < nil
  # pure: true
  # raises: never
  # builtin: true
  def !
  end
  # pure: true
  # raises: never
  # builtin: true
  # returns: Boolean
  def ==(other)
  end
  # pure: true
  # raises: never
  # builtin: true
  # returns: Boolean
  def !=(other)
  end
  # builtin: true
  def __send__(msg, *args, &blk)
  end
  # builtin: true
  # pure: true
  # raises: false
  def equal?(other)
  end
  # builtin: true
  def instance_eval(code = :__not_given__, file='(eval)', line=1)
  end
  # builtin: true
  def instance_exec(*args)
  end
  
 private
  
  # pure: true
  # raises: false
  def initialize(*args)
  end
  # builtin: true
  # raises: always
  def method_missing(symbol, *args, &blk)
    raise ::NoMethodError.new("undefined method #{symbol} for me.")
  end
  # builtin: true
  def singleton_method_added(symbol)
  end
  # builtin: true
  def singleton_method_removed(symbol)
  end
  # builtin: true
  def singleton_method_undefined(symbol)
  end
  
end
