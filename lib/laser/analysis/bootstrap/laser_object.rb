module Laser
  module Analysis
    # Catch all representation of an object. Should never have klass <: Module.
    class LaserObject
      extend ModuleExtensions
      attr_reader :scope, :klass, :name
      attr_writer :singleton_class
      def initialize(klass = ClassRegistry['Object'], scope = Scope::GlobalScope,
                     name = "#<#{klass.path}:#{object_id.to_s(16)}>")
        @klass = klass
        @scope = scope
        @name = name
        @instance_variables = Hash.new do |h, k|
          h[k] = Bindings::InstanceVariableBinding.new(k, nil)
        end
      end
      
      def add_instance_method!(method)
        singleton_class.add_instance_method!(method)
      end
      
      def inspect
        return 'main' if self == Scope::GlobalScope.self_ptr
        super
      end
      
      alias path name

      def normal_class
        if @singleton_class
          return @singleton_class.superclass
        else
          return @klass
        end
      end

      def singleton_class
        return @singleton_class if @singleton_class
        new_scope = ClosedScope.new(self.scope, nil)
        @singleton_class = LaserSingletonClass.new(
            ClassRegistry['Class'], new_scope, "Class:#{name}", self) do |new_singleton_class|
          new_singleton_class.superclass = self.klass
        end
        @klass = @singleton_class
      end

      def laser_simulate(method, args, opts={})
        opts = {self: self, mutation: false}.merge(opts)
        method = klass.instance_method(method)
        method.master_cfg.dup.simulate(args, opts.merge(method: method))
      end

      def instance_variable_defined?(var)
        @instance_variables.has_key?(var)
      end

      def instance_variable_get(var)
        @instance_variables[var].value
      end

      def instance_variable_set(var, value)
        normal_class.instance_variable(var).inferred_type =
            Types::UnionType.new([normal_class.instance_variable(var).expr_type, 
                                  Utilities.normal_class_for(value).as_type])
        @instance_variables[var].bind!(value)
      end
    end
  end
end