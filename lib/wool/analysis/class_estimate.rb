module Wool
  module SexpAnalysis
    # This class is an estimate for a class. It can be either precise or imprecise,
    # and when it is precise, it means (assuming our algorithms are correct!) that
    # a class has been successfully inferred exactly. Note that classes are different
    # from types! This class handles only inferring the classes of things.
    class ClassEstimate
      extend ModuleExtensions
      attr_accessor :upper_bound, :lower_bound
      def initialize(upper_bound = ClassRegistry['Object'], lower_bound = nil)
        self.upper_bound = upper_bound
        self.lower_bound = lower_bound
      end
      
      def exact?
        upper_bound == lower_bound
      end
      opposite_method :inexact?, :exact?
    end
  end
end