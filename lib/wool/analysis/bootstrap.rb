module Wool
  module SexpAnalysis
    module Bootstrap
      def self.bootstrap
        class_class = WoolClass.new('Class', nil)
        module_class = WoolClass.new('Module', nil)
        object_class = WoolClass.new('Object', nil)
        class_scope = OpenScope.new(nil, class_class)
        module_scope = OpenScope.new(nil, module_class)
        object_scope = OpenScope.new(nil, object_class)
        module_class.superclass = object_class
        class_class.superclass = module_class
        main_object = WoolObject.new(object_class, nil, 'main')
        global = OpenScope.new(nil, main_object,
            {'Object' => object_class, 'Module' => module_class, 'Class' => class_class})
        unless Scope.const_defined?("GlobalScope")
          Scope.const_set("GlobalScope", global) 
        end
        class_scope.parent = Scope::GlobalScope
        module_scope.parent = Scope::GlobalScope
        object_scope.parent = Scope::GlobalScope
        object_class.instance_variable_set("@scope", main_object)
        object_class.instance_variable_set("@scope", object_scope)
        module_class.instance_variable_set("@scope", module_scope)
        class_class.instance_variable_set("@scope", class_scope)
        # move these to a real ruby file that gets run through the scanner at
        # boot time
        WoolClass.new('Array') { |klass| klass.superclass = object_class }
        WoolClass.new('Proc')  { |klass| klass.superclass = object_class }
      end
    end
  end
end