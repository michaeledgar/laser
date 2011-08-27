module Laser
  module Analysis
    module IncorrectPredicateMethodDetection
      def incorrect_predicate_methods
        each_user_method.select do |method|
          method.name.end_with?('?')
        end.select do |method|
          !correct_predicate_type?(method.combined_return_type)
        end
      end

      def correct_predicate_type?(return_type)
          (Types.subtype?(Types::FALSECLASS, return_type) ||
           Types.subtype?(Types::NILCLASS, return_type  )) &&
          !Types.subtype?(return_type, Types::FALSY)
      end
    end
  end
end