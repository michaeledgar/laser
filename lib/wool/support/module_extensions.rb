module Wool
  # These are extensions to Wool modules. This module should be
  # extended by any Wool modules seeking to take advantage of them.
  # This prevents conflicts with other libraries defining extensions
  # of the same name.
  module ModuleExtensions
    def cattr_reader(*attrs)
      attrs.each do |attr|
        instance_eval("def #{attr}; @#{attr}; end")
      end
    end
    
    def cattr_writer(*attrs)
      attrs.each do |attr|
        instance_eval("def #{attr}=(val); @#{attr} = val; end")
      end
    end
    
    def cattr_accessor(*attrs)
      cattr_reader(*attrs)
      cattr_writer(*attrs)
    end
    
    def cattr_accessor_with_default(attr, default)
      varname = "@#{attr}".to_sym
      instance_eval do
        define_method attr do
          if instance_variable_defined?(varname)
            instance_variable_get(varname)
          else
            instance_variable_set(varname, default)
            default
          end
        end
        cattr_writer(attr)
      end 
    end
  end
end