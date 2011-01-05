module Wool
  module SexpAnalysis
    # This class models a scope in Ruby. It has a constant table,
    # a self pointer, and a parent pointer to the enclosing scope.
    # It also has a local variable table.
    class Scope
      class ScopeLookupFailure < StandardError
        attr_accessor :scope, :query
        def initialize(scope, query)
          @scope, @query = scope, query
          super("OpenScope #{@scope.inspect} does not contain #{query.inspect}")
        end
      end

      attr_accessor :constants, :self_ptr, :parent, :locals
      def initialize(parent, self_ptr, constants={}, locals={})
        unless respond_to?(:lookup_local)
          raise NotImplementedError.new(
              'must create OpenScope or ClosedScope. Not just OpenScope.')
        end
        @parent, @self_ptr, @constants, @locals = parent, self_ptr, constants, locals
        @locals['self'] = GenericBinding.new('self', self_ptr)
      end
      
      def self_ptr=(other)
        @self_ptr = other
        @locals['self'] = GenericBinding.new('self', other)
      end
      
      def path
        self_ptr.path
      end

      def lookup_or_create_module(new_mod_name)
        begin
          lookup(new_mod_name).scope
        rescue Scope::ScopeLookupFailure => err
          # gotta swizzle in the new scope because the module we create is creating
          # the new scope!
          new_scope = ClosedScope.new(self, nil)
          new_mod = WoolModule.new(submodule_path(new_mod_name), new_scope)
          new_scope
        end
      end

      def lookup_or_create_class(new_class_name, superclass)
        begin
          lookup(new_class_name).scope
        rescue Scope::ScopeLookupFailure => err
          # gotta swizzle in the new scope because the class we create is creating
          # the new scope!
          new_scope = ClosedScope.new(self, nil)
          new_class = WoolClass.new(submodule_path(new_class_name), new_scope) do |klass|
            klass.superclass = superclass
          end
          new_scope
        end
      end
      
      def submodule_path(new_mod_name)
        new_mod_full_path = self == GlobalScope ? '' : path
        new_mod_full_path += "::" unless new_mod_full_path.empty?
        new_mod_full_path += new_mod_name
      end

      def lookup(str)
        if str =~ /^[A-Z]/ && constants[str]
        then constants[str]
        elsif str =~ /^[A-Z]/ && parent
          begin
            parent.lookup(str)
          rescue ScopeLookupFailure => err
            err.scope = self
            raise err
          end
        else lookup_local str
        end
      end

      def lookup_path(path)
        parts = path.split('::')
        parts.inject(self) { |scope, part| scope.lookup(part).scope }
      end
    end
    
    class OpenScope < Scope
      def lookup_local(str)
        if locals[str]
        then locals[str]
        elsif parent then parent.lookup_local(str)
        else raise ScopeLookupFailure.new(self, str)
        end
      end
    end
    
    class ClosedScope < Scope
      def lookup_local(str)
        locals[str] or raise ScopeLookupFailure.new(self, str)
      end
    end
  end
end