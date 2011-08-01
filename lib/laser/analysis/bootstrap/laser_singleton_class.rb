module Laser
  module Analysis
    module SingletonClassFactory
      def self.create_for(ruby_obj)
        if nil == ruby_obj
          return ClassRegistry['NilClass']
        elsif true == ruby_obj
          return ClassRegistry['TrueClass']
        elsif false == ruby_obj
          return ClassRegistry['FalseClass']
        else
          name = "Instance:#{ruby_obj.inspect}"
          existing = ProtocolRegistry[name].first
          existing || LaserSingletonClass.new(
              ClassRegistry['Class'], Scope::GlobalScope, name, ruby_obj) do |new_singleton_class|
            new_singleton_class.superclass = ClassRegistry[ruby_obj.class.name]
          end
        end
      end
    end

    # Singleton classes are important to model separately: they only have one
    # instance! Plus, the built-in classes have some oddities: TrueClass is
    # actually a singleton class, not a normal class. true is its singleton
    # object.
    class LaserSingletonClass < LaserClass
      attr_reader :singleton_instance
      def initialize(klass, scope, path, instance_or_name)
        super(klass, scope, path)
        # Dirty hook for the magic singletons: nil, true, false.
        if String === instance_or_name
          result = LaserObject.new(self, scope, instance_or_name)
          result.singleton_class = self
          @singleton_instance = result
        else
          @singleton_instance = instance_or_name
        end
      end
      def get_instance(scope=nil)
        singleton_instance
      end
    end
  end
end