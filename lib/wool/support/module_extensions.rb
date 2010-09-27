module Wool
  # These are extensions to Wool modules. This module should be
  # extended by any Wool modules seeking to take advantage of them.
  # This prevents conflicts with other libraries defining extensions
  # of the same name.
  module ModuleExtensions
    # Creates a reader for the given instance variables on the class object.
    def cattr_reader(*attrs)
      attrs.each do |attr|
        instance_eval("def #{attr}; @#{attr}; end")
      end
    end

    # Creates a writer for the given instance variables on the class object.
    def cattr_writer(*attrs)
      attrs.each do |attr|
        instance_eval("def #{attr}=(val); @#{attr} = val; end")
      end
    end

    # Creates readers and writers for the given instance variables.
    def cattr_accessor(*attrs)
      cattr_reader(*attrs)
      cattr_writer(*attrs)
    end

    def cattr_accessor_with_default(attr, default)
      varname = "@#{attr}".to_sym
      singleton_class.instance_eval do
        define_method attr do
          if instance_variable_defined?(varname)
            instance_variable_get(varname)
          else
            instance_variable_set(varname, default)
            default
          end
        end
      end
      cattr_writer(attr)
    end

    # Creates a DSL-friendly set-and-getter method. The method, when called with
    # no arguments, acts as a getter. When called with arguments, it acts as a
    # setter. Uses class instance variables - this is not for generating
    # instance methods.
    #
    # @example
    #   class A
    #     cattr_get_and_setter :type
    #   end
    #   class B < A
    #     type :silly
    #   end
    #   p B.type  # => :silly
    def cattr_get_and_setter(*attrs)
      attrs.each do |attr|
        cattr_accessor attr
        singleton_class.instance_eval do
          alias_method "#{attr}_old_get".to_sym, attr
          define_method attr do |*args, &blk|
            if args.size > 0
              send("#{attr}=", *args)
            elsif blk != nil
              send("#{attr}=", blk)
            else
              send("#{attr}_old_get")
            end
          end
        end
      end
    end
  end
end