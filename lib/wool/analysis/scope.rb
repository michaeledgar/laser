module Wool
  module SexpAnalysis
    # This class models a scope in Ruby. It has a constant table,
    # a self pointer, and a parent pointer to the enclosing scope.
    # It also has a local variable table.
    class Scope
      class ScopeLookupFailure < StandardError
        attr_reader :scope, :query
        def initialize(scope, query)
          @scope, @query = scope, query
          super("Scope #{@scope.inspect} does not contain #{query.inspect}")
        end
      end

      attr_accessor :constants, :self_ptr, :parent, :locals
      def initialize(parent, self_ptr, constants={}, locals={})
        @parent, @self_ptr, @constants, @locals = parent, self_ptr, constants, locals
      end

      def inspect
        "#<Scope: #{self_ptr.name}>"
      end
      
      def path
        self_ptr.class_used.path
      end
      
      def lookup_or_create_module(new_mod_name)
        begin
          lookup(new_mod_name)
        rescue Scope::ScopeLookupFailure => err
          new_mod_full_path = path
          new_mod_full_path += "::" unless new_mod_full_path.empty?
          new_mod_full_path += new_mod_name
          # gotta swizzle in the new scope because the module we create is creating
          # the new scope!
          new_scope = Scope.new(self, nil)
          new_mod = WoolModule.new(new_mod_full_path, new_scope)
          new_scope
        end
      end
      
      def lookup(str)
        if str =~ /^[A-Z]/ && constants[str]
        then constants[str]
        elsif locals[str[0,1]]
        else raise ScopeLookupFailure.new(self, str)
        end
      end

      def lookup_path(path)
        parts = path.split('::')
        parts.inject(self) { |scope, part| scope.lookup(part).scope }
      end
    end
  end
end