module Laser::SexpAnalysis
  module SexpExtensions
    module MethodResolution
      def method_estimate
        case type
        when :super, :zsuper
          matched_method = resolve_super_call
          call_arity = method_call_arity
          unless matched_method.arity.compatible?(call_arity)
            call_type = type == :super ? 'explicit' : 'implicit'
            raise IncompatibleArityError.new(
                "Called super with #{call_arity} #{call_type} arguments, but " +
                "the superclass implementation takes #{matched_method.arity} arguments.",
                self)
          end
          Set.new([matched_method])
        when :unary, :binary, :fcall, :call, :command, :var_ref
          filter_by_arity(methods_for_type_name(receiver_type, method_call_name), method_call_arity)
        when :method_add_arg
          meth, args = children
          existing_methods = meth.method_estimate
          if existing_methods.any?
            expansion = ArgumentExpansion.new(args)
            filter_by_arity(meth.method_estimate, expansion.arity)
          end
        end || []
      rescue Error => err
        errors << err
        []
      end
      
      # What is the receiver type (assuming this node is a method call)?
      # returns: Types::Base
      def receiver_type
        receiver = case type
                   when :unary then self[2]
                   when :binary, :call then self[1]
                   when :fcall, :command, :var_ref then scope.lookup('self')
                   end
        receiver.expr_type
      end
      
      # What is the name of the method being called (assuming this node is a
      # method call?)
      # returns: String
      def method_call_name
        case type
        when :unary then self[1].to_s
        when :binary then self[2].to_s
        when :fcall, :command then self[1].expanded_identifier
        when :call then self[3].expanded_identifier
        when :var_ref then expanded_identifier
        end
      end
      
      # What is the (best guess) arity of this method call (assuming this node
      # is a method call?)
      # returns: Arity
      def method_call_arity
        case type
        when :unary, :var_ref then Arity::EMPTY
        when :binary then Arity.new(1..1)
        when :fcall, :call then Arity::ANY
        when :command then ArgumentExpansion.new(self[2]).arity
        when :super then ArgumentExpansion.new(self[1]).arity
        when :zsuper then scope.method.arity
        end
      end
      
      def resolve_super_call
        current_method = scope.method
        if current_method.nil?
          raise NotInMethodError.new('Cannot call super outside of a method.', self)
        end
        superclass = scope.self_ptr.klass.superclass
        if (method = superclass.instance_methods[current_method.name])
          return method
        end
        raise NoSuchMethodError.new(
            "Called super in method '#{current_method.name}', " +
            "but no superclass has a method with that name.", self)
      end

      def methods_for_type_name(type, name)
        methods = type.matching_methods(name)
        if methods.empty?
          raise NoSuchMethodError.new("Could not find any methods named #{name}.", self)
        end
        methods
      end
      
      def filter_by_arity(methods, arity)
        name = methods.first.name
        pruned_methods = methods.select { |meth| meth.arity.compatible?(arity) }
        if pruned_methods.empty?
          raise NoSuchMethodError.new("Could not find any methods named #{name} that take 0 arguments.", self)
        end
        pruned_methods
      end
    end
  end
end