
class Exception < Object
end
class SystemExit < Exception
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


module Errno
end
class Errno::NOERROR < SystemCallError
end
class Errno::EPERM < SystemCallError
end
class Errno::ENOENT < SystemCallError
end
class Errno::ESRCH < SystemCallError
end
class Errno::EINTR < SystemCallError
end
class Errno::EIO < SystemCallError
end
class Errno::ENXIO < SystemCallError
end
class Errno::E2BIG < SystemCallError
end
class Errno::ENOEXEC < SystemCallError
end
class Errno::EBADF < SystemCallError
end
class Errno::ECHILD < SystemCallError
end
class Errno::EAGAIN < SystemCallError
end
class Errno::ENOMEM < SystemCallError
end
class Errno::EACCES < SystemCallError
end
class Errno::EFAULT < SystemCallError
end
class Errno::ENOTBLK < SystemCallError
end
class Errno::EBUSY < SystemCallError
end
class Errno::EEXIST < SystemCallError
end
class Errno::EXDEV < SystemCallError
end
class Errno::ENODEV < SystemCallError
end
class Errno::ENOTDIR < SystemCallError
end
class Errno::EISDIR < SystemCallError
end
class Errno::EINVAL < SystemCallError
end
class Errno::ENFILE < SystemCallError
end
class Errno::EMFILE < SystemCallError
end
class Errno::ENOTTY < SystemCallError
end
class Errno::ETXTBSY < SystemCallError
end
class Errno::EFBIG < SystemCallError
end
class Errno::ENOSPC < SystemCallError
end
class Errno::ESPIPE < SystemCallError
end
class Errno::EROFS < SystemCallError
end
class Errno::EMLINK < SystemCallError
end
class Errno::EPIPE < SystemCallError
end
class Errno::EDOM < SystemCallError
end
class Errno::ERANGE < SystemCallError
end
class Errno::EDEADLK < SystemCallError
end
class Errno::ENAMETOOLONG < SystemCallError
end
class Errno::ENOLCK < SystemCallError
end
class Errno::ENOSYS < SystemCallError
end
class Errno::ENOTEMPTY < SystemCallError
end
class Errno::ELOOP < SystemCallError
end
class Errno::ENOMSG < SystemCallError
end
class Errno::EIDRM < SystemCallError
end
class Errno::ENOSTR < SystemCallError
end
class Errno::ENODATA < SystemCallError
end
class Errno::ETIME < SystemCallError
end
class Errno::ENOSR < SystemCallError
end
class Errno::EREMOTE < SystemCallError
end
class Errno::ENOLINK < SystemCallError
end
class Errno::EPROTO < SystemCallError
end
class Errno::EMULTIHOP < SystemCallError
end
class Errno::EBADMSG < SystemCallError
end
class Errno::EOVERFLOW < SystemCallError
end
class Errno::EILSEQ < SystemCallError
end
class Errno::EUSERS < SystemCallError
end
class Errno::ENOTSOCK < SystemCallError
end
class Errno::EDESTADDRREQ < SystemCallError
end
class Errno::EMSGSIZE < SystemCallError
end
class Errno::EPROTOTYPE < SystemCallError
end
class Errno::ENOPROTOOPT < SystemCallError
end
class Errno::EPROTONOSUPPORT < SystemCallError
end
class Errno::ESOCKTNOSUPPORT < SystemCallError
end
class Errno::EOPNOTSUPP < SystemCallError
end
class Errno::EPFNOSUPPORT < SystemCallError
end
class Errno::EAFNOSUPPORT < SystemCallError
end
class Errno::EADDRINUSE < SystemCallError
end
class Errno::EADDRNOTAVAIL < SystemCallError
end
class Errno::ENETDOWN < SystemCallError
end
class Errno::ENETUNREACH < SystemCallError
end
class Errno::ENETRESET < SystemCallError
end
class Errno::ECONNABORTED < SystemCallError
end
class Errno::ECONNRESET < SystemCallError
end
class Errno::ENOBUFS < SystemCallError
end
class Errno::EISCONN < SystemCallError
end
class Errno::ENOTCONN < SystemCallError
end
class Errno::ESHUTDOWN < SystemCallError
end
class Errno::ETOOMANYREFS < SystemCallError
end
class Errno::ETIMEDOUT < SystemCallError
end
class Errno::ECONNREFUSED < SystemCallError
end
class Errno::EHOSTDOWN < SystemCallError
end
class Errno::EHOSTUNREACH < SystemCallError
end
class Errno::EALREADY < SystemCallError
end
class Errno::EINPROGRESS < SystemCallError
end
class Errno::ESTALE < SystemCallError
end
class Errno::EDQUOT < SystemCallError
end
class Errno::ECANCELED < SystemCallError
end
class Errno::EAUTH < SystemCallError
end
class Errno::EBADRPC < SystemCallError
end
class Errno::EFTYPE < SystemCallError
end
class Errno::ENEEDAUTH < SystemCallError
end
class Errno::ENOATTR < SystemCallError
end
class Errno::ENOTSUP < SystemCallError
end
class Errno::EPROCLIM < SystemCallError
end
class Errno::EPROCUNAVAIL < SystemCallError
end
class Errno::EPROGMISMATCH < SystemCallError
end
class Errno::EPROGUNAVAIL < SystemCallError
end
class Errno::ERPCMISMATCH < SystemCallError
end