module Laser::SexpAnalysis
  module SexpExtensions
    module MethodResolution
      def method_estimate
        case type
        when :super
          matched_method = resolve_super_call(self)
          result = Set.new([matched_method])
          call_arity = ArgumentExpansion.new(self[1]).arity
          unless matched_method.arity.compatible?(call_arity)
            raise IncompatibleArityError.new(
                "Called super with #{call_arity} implicit arguments, but " +
                "the superclass implementation takes #{matched_method.arity} arguments.",
                self)
          end
        when :zsuper
          matched_method = resolve_super_call(self)
          result = Set.new([matched_method])
          call_arity = scope.method.arity
          unless matched_method.arity.compatible?(call_arity)
            raise IncompatibleArityError.new(
                "Called super with #{call_arity} implicit arguments, but " +
                "the superclass implementation takes #{matched_method.arity} arguments.",
                self)
          end
        when :unary
          op, rhs = children
          type = rhs.expr_type
          name = op.to_s
          result = filter_by_arity(methods_for_type_name(type, name, self),
                                   name, Arity::EMPTY, self)
        when :binary
          lhs, op, rhs = children
          type = lhs.expr_type
          name = op.to_s
          result = filter_by_arity(methods_for_type_name(type, name, self),
                                   name, Arity.new(1..1), self)
        when :fcall
          meth = self[1]
          type = scope.lookup('self').expr_type
          name = meth.expanded_identifier
          result = methods_for_type_name(type, name, self)
        when :call
          recv, sep, meth = children
          type = recv.expr_type
          name = meth.expanded_identifier
          result = methods_for_type_name(type, name, self)
        when :command
          meth, args = children
          type = scope.lookup('self').expr_type
          name = meth.expanded_identifier
          expansion = ArgumentExpansion.new(args)
          result = filter_by_arity(
              methods_for_type_name(type, name, self), name, expansion.arity, self)
        when :var_ref
          return nil unless binding.nil?
          type = scope.lookup('self').expr_type
          name = expanded_identifier
          result = filter_by_arity(
              methods_for_type_name(type, name, self), name, Arity::EMPTY, self)
        when :method_add_arg
          meth, args = children
          existing_methods = meth.method_estimate
          if existing_methods.any?
            expansion = ArgumentExpansion.new(args)
            result = filter_by_arity(
                meth.method_estimate, existing_methods.first.name, expansion.arity, self)
          else
            result = []
          end
        else
          result = []
        end
        result
      rescue Error => err
        errors << err
        return []
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
        raise NoSuchMethodError.new(
            "Called super in method '#{current_method.name}', " +
            "but no superclass has a method with that name.", node)
      end

      def methods_for_type_name(type, name, node)
        methods = type.matching_methods(name)
        if methods.empty?
          raise NoSuchMethodError.new("Could not find any methods named #{name}.", node)
        end
        methods
      end
      
      def filter_by_arity(methods, name, arity, node)
        pruned_methods = methods.select { |meth| meth.arity.compatible?(arity) }
        if pruned_methods.empty?
          raise NoSuchMethodError.new("Could not find any methods named #{name} that take 0 arguments.", node)
        end
        pruned_methods
      end
    end
  end
end