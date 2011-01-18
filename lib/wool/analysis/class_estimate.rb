module Wool
  module SexpAnalysis
    # This class is an estimate for a class. It can be either precise or imprecise,
    # and when it is precise, it means (assuming our algorithms are correct!) that
    # a class has been successfully inferred exactly. Note that classes are different
    # from types! This class handles only inferring the classes of things.
    #
    # This class is mutable, but each mutation is required to be consistent with
    # previous ones. It only permits consistent modifications that increase the
    # specificity of the class estimate.
    class ClassEstimate
      extend ModuleExtensions
      attr_reader :upper_bound, :lower_bound
      def initialize(upper_bound = ClassRegistry['Object'], lower_bound = nil)
        @upper_bound = upper_bound
        @lower_bound = lower_bound
      end

      # Is this an exact estimate - one which has zeroed in on a specific class?
      def exact?
        upper_bound == lower_bound
      end
      opposite_method :inexact?, :exact?

      # Returns the exact estimate, and raises if there is none.
      def exact_class
        if exact?
        then upper_bound
        else raise "Tried to get the exact class from an inexact class estimate."
        end
      end

      # Returns the set of all possible classes this estimate represents.
      def possible_classes
        result = upper_bound.subset
        result -= lower_bound.proper_subset if lower_bound
        result
      end

      # Sets the new upper bound on the class estimate. This could raise if the
      # new upper bound is incompatible with previous estimates.
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

      # Sets the new lower bound on the class estimate. This could raise if the
      # new lower bound is incompatible with previous estimates.
      def lower_bound=(new_lower_bound)
        if lower_bound && lower_bound.subset.include?(new_lower_bound)  # no-op
        elsif !lower_bound || (lower_bound && lower_bound.superset.include?(new_lower_bound))
          @lower_bound = new_lower_bound
          if upper_bound.proper_superset.include?(lower_bound)
            raise "Type error - lower bound #{lower_bound} crosses upper bound #{upper_bound}"
          end
        else
          raise "Type error - lower bound #{new_lower_bound} is not related "+
                " to current lower bound #{lower_bound}"
        end
      end
    end
    
    class ExactClassEstimate < ClassEstimate
      def initialize(exact_class)
        super(exact_class, exact_class)
      end
    end
  end
end