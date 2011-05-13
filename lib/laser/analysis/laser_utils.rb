module Laser
  module SexpAnalysis
    module Utilities
     module_function
      def klass_for(arg)
        LaserObject === arg ? arg.klass : ClassRegistry[arg.class.name]
      end

      def type_for(arg, variance=:invariant)
        Types::ClassType.new(klass_for(arg).path, variance)
      end
    end
  end
end
