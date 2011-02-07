module Laser
  module SexpAnalysis
    # This annotation attempts to resolve a method call to a set of methods
    # that may be the target of that invocation. This relies on both the
    # name of the method, the receiver's type, and then its arity. Lots of
    # bugs can be found here!
    class MethodResolutionAnnotation < BasicAnnotation
      add_property :method_estimate
      
      add :super do |node|
        matched_method = resolve_super_call(node)
        node.method_estimate = Set.new([matched_method])
        call_arity = ArgumentExpansion.new(node[1]).arity
        unless arity_compatible?(matched_method.arity, call_arity)
          raise IncompatibleArityError.new(
              "Called super with #{call_arity} implicit arguments, but " +
              "the superclass implementation takes #{matched_method.arity} arguments.",
              node)
        end
      end
      
      add :zsuper do |node|
        matched_method = resolve_super_call(node)
        node.method_estimate = Set.new([matched_method])
        call_arity = node.scope.method.arity
        unless arity_compatible?(matched_method.arity, call_arity)
          raise IncompatibleArityError.new(
              "Called super with #{call_arity} implicit arguments, but " +
              "the superclass implementation takes #{matched_method.arity} arguments.",
              node)
        end
      end
      
      def arity_compatible?(r1, r2)
        r1.first <= r2.last && r2.first <= r1.last
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
        raise NoSuchMethodError.new("Called super in method '#{current_method.name}', " +
                                    "but no superclass has a method with that name.", node)
      end
      
      add :var_ref do |node|
        next unless node.binding.nil?
        
      end
    end
  end
end