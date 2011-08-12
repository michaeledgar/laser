module Laser
  module Version
    MAJOR = 0
    MINOR = 7
    PATCH = 0
    BUILD = 'pre1'

    if BUILD.empty?
      STRING = [MAJOR, MINOR, PATCH].compact.join('.')
    else
      STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
    end
  end
end