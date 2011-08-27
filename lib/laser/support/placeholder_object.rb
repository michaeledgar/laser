module Laser
  # Class that's just a name. Substitute for symbols, which can overlap
  # with user-code values.
  class PlaceholderObject
    def initialize(name)
      @name = name
    end
    def inspect
      @name
    end
    alias_method :to_s, :inspect
  end
end
