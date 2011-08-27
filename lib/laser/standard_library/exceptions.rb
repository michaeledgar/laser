class Exception < Object
  def initialize(msg=nil)
    @__mesg__ = msg
    @__bt__ = nil
  end
  def backtrace
    @__bt__
  end
  def to_s
    @__mesg__ ? (@__mesg__.to_str) : self.class.name
    #@__mesg__ ? (@__mesg__.to_s rescue @__mesg__) : self.class.name
  end
  alias message to_s
  BT_FAILURE_MESSAGE = "backtrace must be Array of String"
  def __check_backtrace__(bt)
    return bt if NilClass === bt
    if String === bt
      [bt]
    elsif Array === bt
      unless bt.all? { |x| String === x }
        raise TypeError.new(BT_FAILURE_MESSAGE)
      end
    else
      raise TypeError.new(BT_FAILURE_MESSAGE)
    end
  end
  private :__check_backtrace__
  def set_backtrace(new_bt)
    @__bt__ = __check_backtrace__(new_bt)
  end
end
class SystemExit < Exception
  EXIT_SUCCESS = 0
  def initialize(val=nil, msg=nil)
    if Fixnum === val
      @__status__ = val
      super(msg)
    else
      super(val)
    end
  end
  def status
    @__status__
  end
  def success?
    @__status__.nil? || @__status__ == EXIT_SUCCESS
  end
end
# class fatal < Exception
# end
class SignalException < Exception
end
class Interrupt < SignalException
end
class StandardError < Exception
end
class TypeError < StandardError
end
# Since TypeErrors often have specific semantic meanings, I'd rather
# use a class for each. But I have to make sure user code isn't impacted
# by this choice, so we must override #class. TypeError#=== and rescues
# will still work.
class LaserTypeErrorWrapper < TypeError
  def class
    TypeError
  end
end
class LaserReopenedClassAsModuleError < LaserTypeErrorWrapper
end
class LaserReopenedModuleAsClassError < LaserTypeErrorWrapper
end
class LaserSuperclassMismatchError < LaserTypeErrorWrapper
end
class ArgumentError < StandardError
end
class IndexError < StandardError
end
class KeyError < IndexError
end
class RangeError < StandardError
end
class ScriptError < Exception
end
class SyntaxError < ScriptError
end
class LoadError < ScriptError
end
class NotImplementedError < ScriptError
end
class NameError < StandardError
  def initialize(msg=nil, name=nil)
    @__name__ = name
    @__mesg__ = msg
    @__bt__ = nil
  end
  def name
    @__name__
  end
end
class NoMethodError < NameError
end
class RuntimeError < StandardError
end
class SecurityError < Exception
end
class NoMemoryError < Exception
end
class EncodingError < StandardError
end
class SystemCallError < StandardError
end
class ZeroDivisionError < StandardError
end
class FloatDomainError < RangeError
end
class RegexpError < StandardError
end
class IOError < StandardError
end
class EOFError < IOError
end
class LocalJumpError < StandardError
end
class SystemStackError < Exception
end
module Math
  class DomainError < StandardError
  end
end
class StopIteration < IndexError
end
class ThreadError < StandardError
end
class FiberError < StandardError
end
