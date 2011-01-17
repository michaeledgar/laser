module Wool
  module SexpAnalysis
    # This class is an estimate for a class. It can be either precise or imprecise,
    # and when it is precise, it means (assuming our algorithms are correct!) that
    # a class has been successfully inferred exactly. Note that classes are different
    # from types! This class handles only inferring the classes of things.
    class ClassEstimate
      extend ModuleExtensions
      attr_reader :upper_bound, :lower_bound
      def initialize(upper_bound = ClassRegistry['Object'], lower_bound = nil)
        @upper_bound = upper_bound
        @lower_bound = lower_bound
      end
      
      def exact?
        upper_bound == lower_bound
      end
      opposite_method :inexact?, :exact?
      
      def upper_bound=(new_upper_bound)
        # Three cases relative to the old upper bound:
        # 1. new upper bound is a superclass of the current one. No new information.
        # 2. new upper bound is a subclass of the current upper bound. Refine the upper bound.
        # 3. new upper bound is neither a superclass nor a subclass. Type error.
        #
        # Also note: if the new upper bound crosses the lower bound, then 
        if upper_bound.superset.include?(new_upper_bound)  # no-op
        elsif upper_bound.subset.include?(new_upper_bound)
          @upper_bound = new_upper_bound
          if lower_bound && lower_bound.proper_subset.include?(upper_bound)
            raise "Type error - upper bound #{upper_bound} crosses lower bound #{lower_bound}"
          end
        else
          raise "Type error - upper bound #{new_upper_bound} is not related "+
                " to current upper bound #{upper_bound}"
        end
      end
    end
  end
end