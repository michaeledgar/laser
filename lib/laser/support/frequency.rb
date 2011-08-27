module Laser
  class Frequency
    include Comparable
    attr_reader :name, :val
    def initialize(name, val)
      @name = name
      @val = val
    end
    
    def ===(other)
      equal? other
    end
    
    def to_s
      @name.to_s
    end
    alias inspect to_s
    
    def <=>(other)
      @val <=> other.val
    end
    
    NEVER = self.new(:never, 0)
    MAYBE = self.new(:maybe, 1)
    ALWAYS = self.new(:always, 2)
    
    LOOKUP = {never: NEVER, maybe: MAYBE, always: ALWAYS}
    def self.[](sym)
      LOOKUP[sym]
    end

    def self.combine_samples(samples)
      return NEVER if samples.empty?
      base = samples.first
      samples[1..-1].each do |sample|
        return MAYBE if sample > base || sample < base
      end
      base
    end   

    def self.for_samples(yes, no)
      if no && !yes
        NEVER
      elsif no && yes
        MAYBE
      else  # !no && yes
        ALWAYS
      end
    end

    class << self
      undef new
    end
  end
end
