module Wool
  module SexpAnalysis
    # This class represents a Symbol in Ruby. It may have a known protocol (type),
    # class, value (if constant!), and a variety of other details.
    class Symbol < Struct.new(:protocol, :class_used, :value, :scope)
      include Comparable
      
    end
  end
end