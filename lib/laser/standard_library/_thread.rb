class Thread
  class << self
    def abort_on_exception
    end
    
    def abort_on_exception=(bool)
    end
    
    def current
    end
    
    # yields: once
    def exclusive
    end
    
    def exit
    end
    
    def start(*args)
    end
    alias :fork :start
    
    def kill(thread)
    end
    
    def list
    end
    
    def main
    end
    
    def pass
    end
    
    def stop
    end
  end
  
  def [](key)
  end
  
  def []=(key, val)
  end
  
  def abort_on_exception
  end
  
  def abort_on_exception=(val)
  end
  
  def add_trace_func(proc)
  end
  
  def alive?
  end
  
  def backtrace
  end
  
  def exit
  end
  alias kill exit
  alias terminate exit
  
  def group
  end
  
  def inspect
  end
  
  def join(limit=nil)
  end
  
  def key?(sym)
  end
  
  def keys
  end
  
  def priority
  end
  
  def priority=(val)
  end
  
  def raise(*args)
  end
  
  def run
  end
  
  def safe_level
  end
  
  def set_trace_func(proc)
  end
  
  def status
  end
  
  def stop?
  end
  
  def value
  end
  
  def wakeup
  end
end