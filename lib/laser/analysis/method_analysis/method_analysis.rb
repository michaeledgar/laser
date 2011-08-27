require_relative 'incorrect_predicate_method_detection'
require_relative 'unused_methods'
module Laser
  module Analysis
    # General-purpose method analysis functions.
    module MethodAnalysis
      extend UnusedMethodDetection
      extend IncorrectPredicateMethodDetection
      def self.each_user_method
        return enum_for(__method__) unless block_given?
        classes = Set[]
        Analysis::ProtocolRegistry.class_protocols.each do |key, klass|
          if should_analyze?(klass) && !classes.include?(klass)
            classes << klass
            klass.__all_instance_methods(false).each do |name|
              yield klass.instance_method(name)
            end
          end
        end
      end

      def self.should_analyze?(klass)
        !(Analysis::LaserSingletonClass === klass) ||
          klass < ClassRegistry['Module']
      end
    end
  end
end
