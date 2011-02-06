module Laser
  module SexpAnalysis
    # This annotation attempts to resolve a method call to a set of methods
    # that may be the target of that invocation. This relies on both the
    # name of the method, the receiver's type, and then its arity. Lots of
    # bugs can be found here!
    class MethodResolutionAnnotation < BasicAnnotation
      add_property :method_estimate
      
      add :super do |node|
        current_method = node.scope.method
        if current_method.nil?
          raise NotInMethodError.new('Cannot call super outside of a method.', node)
        end
        
      end
    end
  end
end