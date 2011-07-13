module Laser
  module SexpAnalysis
    module Utilities
     module_function
      def klass_for(arg)
        LaserObject === arg ? arg.singleton_class : ClassRegistry[arg.class.name]
      end

      def type_for(arg, variance=:invariant)
        Types::ClassObjectType.new(klass_for(arg))
      end
      
      def normal_class_for(arg)
        LaserObject === arg ? arg.normal_class : ClassRegistry[arg.class.name]
      end
    end
  end
end
