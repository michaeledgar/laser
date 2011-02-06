module Laser
  module SexpAnalysis
    # This annotation attempts to resolve a method call to a set of methods
    # that may be the target of that invocation. This relies on both the
    # name of the method, the receiver's type, and then its arity. Lots of
    # bugs can be found here!
    class MethodResolutionAnnotation < BasicAnnotation
      add_property :method_estimate
      
      add :super, :zsuper do |node|
        node.method_estimate = Set.new([resolve_super_call(node)])
      end
      
      def resolve_super_call(node)
        current_method = node.scope.method
        if current_method.nil?
          raise NotInMethodError.new('Cannot call super outside of a method.', node)
        end
        superclass = node.scope.self_ptr.klass.superclass
        if (method = superclass.instance_methods[current_method.name])
          return method
        end
        raise NoSuchMethodError.new("Called super in method '#{current_method.name}'" +
                                    ", but no superclass has a method with that name.", node)
      end
    end
  end
end