module Laser
  module SexpAnalysis
    # This class takes a class estimate and combines it with information about
    # a method, and attempts to resolve that information to as small of a set
    # of methods as possible. The class estimate is for the receiver.
    class MethodEstimate
      def initialize(class_estimate, name, arity=Arity.new(0..Float::INFINITY))
        @class_estimate = class_estimate
        @name = name
        @arity = arity
      end

      # Returns the set of methods that matches the name and arity of the method
      # estimate.
      def estimate
        classes = @class_estimate.possible_classes
        methods = classes.map { |klass| klass.instance_methods[@name] }.uniq
        methods.select { |method| @arity.compatible?(method.arity) }
      end
    end
  end
end