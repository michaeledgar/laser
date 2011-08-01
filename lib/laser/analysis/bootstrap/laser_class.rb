module Laser
  module Analysis
    # Laser representation of a class. I named it LaserClass so it wouldn't
    # clash with regular Class. This links the class to its protocol.
    # It inherits from LaserModule to pull in everything but superclasses.
    class LaserClass < LaserModule
      attr_reader :subclasses
      
      def initialize(klass = ClassRegistry['Class'], scope = Scope::GlobalScope,
                     full_path=(@name_set = :no; "#{klass.path}:Anonymous:#{object_id.to_s(16)}"))
        @subclasses ||= []
        # bootstrapping exception
        unless ['Class', 'Module', 'Object', 'BasicObject'].include?(full_path)
          @superclass = ClassRegistry['Object']
        end
        super # can yield, so must come last
      end
      
      def normal_class
        return ClassRegistry['Class']
      end

      def singleton_class
        return @singleton_class if @singleton_class
        new_scope = ClosedScope.new(self.scope, nil)
        @singleton_class = LaserSingletonClass.new(
            ClassRegistry['Class'], new_scope, "Class:#{name}", self) do |new_singleton_class|
          if superclass
            new_singleton_class.superclass = superclass.singleton_class
          else
            new_singleton_class.superclass = ClassRegistry['Class']
          end 
        end
        @klass = @singleton_class
      end
      
      # Adds a subclass.
      def add_subclass!(other)
        subclasses << other
      end
      
      # Removes a subclass.
      def remove_subclass!(other)
        subclasses.delete other
      end
      
      def parent
        @superclass
      end
      
      def superclass
        current = @superclass
        while current
          if LaserModuleCopy === current
            current = current.superclass
          else
            return current
          end
        end
      end
      
      # Sets the superclass, which handles registering/unregistering subclass
      # ownership elsewhere in the inheritance tree
      def superclass=(other)
        if LaserModuleCopy === other # || LaserSingletonClass === self
          @superclass = other
        else
          superclass.remove_subclass! self if superclass
          @superclass = other
          superclass.add_subclass! self
        end
      end
      
      # The set of all superclasses (including the class itself). Excludes modules.
      def superset
        if superclass.nil?
        then [self]
        else [self] + superclass.superset
        end
      end
      
      # The set of all superclasses (excluding the class itself)
      def proper_superset
        superset - [self]
      end
      
      # The set of all subclasses (including the class itself)
      def subset
        [self] + subclasses.map(&:subset).flatten
      end
      
      # The set of all subclasses (excluding the class itself)
      def proper_subset
        subset - [self]
      end
      
      def class_name
        'Class'
      end
      
      def inspect
        "#<LaserClass: #{path} superclass=#{superclass.inspect}>"
      end
    end
  end
end