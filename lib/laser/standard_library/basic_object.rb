class BasicObject < nil
  # pure: true
  # raises: false
  def !
  end

  # pure: true
  # raises: false
  def ==(other)
  end

  # pure: true
  # raises: false
  def !=(other)
  end
  
  def __send__(msg, *args, &blk)
  end
  
  def equal?(other)
  end
  
  def instance_eval(code = :__not_given__, file='(eval)', line=1)
  end
  
  def instance_exec(*args)
  end
  
 private
  
  def initialize(*args)
  end
  def method_missing(symbol, *args, &blk)
  end
  def singleton_method_added(symbol)
  end
  def singleton_method_removed(symbol)
  end
  def singleton_method_undefined(symbol)
  end
  
end