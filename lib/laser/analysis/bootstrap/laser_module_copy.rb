require 'delegate'
module Laser
  module Analysis
    
    # When you include a module in Ruby, it uses inheritance to model the
    # relationship with the included module. This is how Ruby achieves
    # multiple inheritance. However, to avoid destroying the tree shape of
    # the inheritance hierarchy, when you include a module, it is *copied*
    # and inserted between the current module/class and its superclass.
    # It is marked as a T_ICLASS instead of a T_CLASS because it is an
    # "internal", invisible class: it shouldn't show up when you use #superclass.
    #
    # Yes, that means even modules have superclasses. There's just no method
    # to expose them because a module only ever has a null superclass or a
    # copied-module superclass.
    class LaserModuleCopy < DelegateClass(LaserClass)
      attr_reader :delegated
      def initialize(module_to_copy, with_super)
        super(module_to_copy)
        case module_to_copy
        when LaserModuleCopy then @delegated = module_to_copy.delegated
        else @delegated = module_to_copy
        end
        @superclass = with_super
      end
      
      def superclass
        @superclass
      end
      
      def superclass=(other)
        @superclass = other
      end
      
      def ==(other)
        case other
        when LaserModuleCopy then @delegated == other.delegated
        else @delegated == other
        end
      end
      
      # Redefined because otherwise it'll get delegated. Meh.
      # TODO(adgar): Find a better solution than just copy-pasting this method.
      def ancestors
        if @superclass.nil?
        then [self]
        else [self] + @superclass.ancestors
        end
      end
      
      def instance_variables
        @delegated.instance_variables
      end
      
      def instance_method(name)
        sym = name.to_sym
        return @delegated.instance_method(sym) ||
          (@superclass && @superclass.instance_method(sym))
      end
      
      def visibility_for(method)
        return @delegated.visibility_for(method) ||
          (@superclass && @superclass.visibility_for(method))
      end

      def instance_methods(include_superclass = true)
        if include_superclass && @superclass
        then @superclass.instance_methods | @delegated.instance_methods
        else @delegated.instance_methods
        end
      end
    end
  end
end