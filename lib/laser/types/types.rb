require 'set'
module Laser
  module Types
    # All these relations are very inefficient, but they don't show up in
    # profiling, yet.
    #
    # Subtype relation. Extremely important. Don't mess it up.
    def self.subtype?(sub, top)
      sub.possible_classes.subset?(top.possible_classes)
    end
    
    def self.equal?(t1, t2)
      t1.possible_classes == t2.possible_classes
    end
    
    def self.overlap?(t1, t2)
      !(t1.possible_classes & t2.possible_classes).empty?
    end
    
    def self.optional(t1)
      Types::UnionType.new([t1, Types::NILCLASS])
    end
    
    class Base
      extend ActsAsStruct

      def |(other)
        UnionType.new([self, other])
      end

      def hash
        signature.values.map(&:hash).inject(:+)
      end

      def eql?(other)
        self == other
      end

      def ==(other)
        signature.inject(true) {|cur, (name, val)| cur && (val == other.send(name)) }
      end
    end

    class UnionType < Base
      acts_as_struct :member_types
      def initialize(member_types)
        @member_types = Set.new(flatten_unions(member_types))
      end

      def flatten_unions(types)
        result = []
        types.each do |type|
          if UnionType === type
            result += type.member_types.to_a
          else
            result << type
          end
        end
        result
      end

      def signature
        {member_types: member_types}
      end
      
      def possible_classes
        member_types.map { |type| type.possible_classes }.inject(:|) || Set[]
      end

      def public_matching_methods(name)
        name = name.to_s
        member_types.map { |type| type.public_matching_methods(name) }.flatten.uniq
      end

      def matching_methods(name)
        name = name.to_s
        member_types.map { |type| type.matching_methods(name) }.flatten.uniq
      end
    end

    class SelfType < Base
      acts_as_struct :scope
      
      def signature
        {scope: scope}
      end
    end
    
    class StructuralType < Base
      acts_as_struct :method_name, :argument_types, :return_type
      
      def signature
        {method_name: method_name, argument_types: argument_types,
         return_type: return_type}
      end
    end
    
    class ClassObjectType < Base
      attr_reader :class_object
      def initialize(class_object)
        if String === class_object
          @class_object = SexpAnalysis::ClassRegistry[class_object]
        else
          @class_object = class_object
        end
      end

      def ==(other)
        Types::equal?(self, other)
      end

      def inspect
        "#<ClassObjectType: #{class_object.name}>"
      end
      
      def member_types
        [self]
      end
      
      def possible_classes
        Set[class_object]
      end
      
      def matching_methods(name)
        [*class_object.instance_method(name)]
      end
      
      def public_matching_methods(name)
        [*class_object.public_instance_method(name)]
      end
      
      def class_name
        class_object.name
      end
      
      def variance
        :invariant
      end
      
      def signature
        {class_name: class_object.name, variance: :invariant}
      end
    end
    
    class ClassType < Base
      acts_as_struct :class_name, :variance
      def inspect
        "#<Class: #{class_name} variance: #{variance}>"
      end
      
      def member_types
        [self]
      end

      def public_matching_methods(name)
        name = name.to_s
        possible_classes.map do |klass|
          klass.instance_method(name) if klass.visibility_table[name] == :public
        end.compact.uniq
      end
      
      def matching_methods(name)
        name = name.to_s
        possible_classes.map { |klass| klass.instance_method(name) }.compact.uniq
      end
      
      def possible_classes
        klass = SexpAnalysis::ClassRegistry[class_name]
        case variance
        when :invariant then ::Set[klass]
        when :covariant
          if SexpAnalysis::LaserClass === klass
          then ::Set.new klass.subset
          else ::Set.new klass.classes_including.map(&:subset).flatten  # module
          end
        when :contravariant then ::Set.new klass.superset
        end
      end
      
      def signature
        {class_name: class_name, variance: variance}
      end
    end

    TOP = ClassType.new('BasicObject', :covariant)
    STRING = ClassObjectType.new('String')
    FIXNUM = ClassObjectType.new('Fixnum')
    BIGNUM = ClassObjectType.new('Bignum')
    FLOAT = ClassObjectType.new('Float')
    ARRAY = ClassObjectType.new('Array')
    HASH = ClassObjectType.new('Hash')
    PROC = ClassObjectType.new('Proc')
    NILCLASS = ClassObjectType.new('NilClass')
    TRUECLASS = ClassObjectType.new('TrueClass')
    FALSECLASS = ClassObjectType.new('FalseClass')
    FALSY = UnionType.new([FALSECLASS, NILCLASS])
    BOOLEAN = UnionType.new([TRUECLASS, FALSECLASS])
    BLOCK = UnionType.new([PROC, NILCLASS])
    EMPTY = UnionType.new([])

    class GenericType < Base
      acts_as_struct :base_type, :subtypes

      def signature
        {base_type: base_type, subtypes: subtypes}
      end
    end
    
    # Represents a Tuple: an array of a given, fixed size, with each position
    # in the array possessing a set of constraints.
    class TupleType < Base
      attr_reader :element_types
      def initialize(element_types)
        @element_types = element_types
      end
      
      def size
        element_types.size
      end
      
      def [](idx)
        element_types[idx]
      end
      
      def possible_classes
        ::Set[ClassRegistry['Array']]
      end

      def member_types
        [self]
      end
      
      def public_matching_methods(name)
        name = name.to_s
        case name
        when '[]'
          [TupleIndexMethod.new(self)]
        when 'to_a', 'to_ary'
          [TupleSelfMethod.new(self, name)]
        else
          Types::ARRAY.public_matching_methods(name)
        end
      end
      
      def matching_methods(name)
        name = name.to_s
        case name
        when '[]'
          [TupleIndexMethod.new(self)]
        when 'to_a', 'to_ary'
          [TupleSelfMethod.new(self, name)]
        else
          Types::ARRAY.matching_methods(name)
        end
      end
      
      def signature
        {element_types: element_types}
      end
      
      class TupleMethod
        attr_reader :tuple_type

        def initialize(tuple_type)
          @tuple_type = tuple_type
        end

        def method_missing(method, *args, &blk)
          ClassRegistry['Array'].instance_method(name).send(method, *args, &blk)
        end
      end
      
      class TupleSelfMethod < TupleMethod
        attr_reader :name

        def initialize(tuple_type, name)
          @name = name
          super(tuple_type)
        end
      
        def return_type_for_types(self_type, arg_types = [], block_type = nil)
          tuple_type
        end
        
        def raise_frequency_for_types(self_type, arg_types = [], block_type = nil)
          Frequency::NEVER
        end
        
        def raise_type_for_types(self_type, arg_types = [], block_type = nil)
          Types::EMPTY
        end
      end
      
      class TupleIndexMethod < TupleMethod
        def name
          '[]'
        end
        
        def return_type_for_types(self_type, arg_types = [], block_type = nil)
          resulting_choices = Set.new
          element_types = tuple_type.element_types
          if arg_types.size == 1
            Laser.debug_puts "computing return type of tuple#[]"
            arg_types[0].member_types.each do |member_type|
              member_type.possible_classes.each do |klass|
                Laser.debug_puts "potential arg klass: #{klass.inspect}"
                if LaserSingletonClass === klass && klass < ClassRegistry['Fixnum']
                  Laser.debug_puts "specific fixnum: #{klass.get_instance}"
                  Laser.debug_puts "indexes into #{tuple_type.inspect} to get #{element_types[klass.get_instance].inspect}"
                  resulting_choices << (element_types[klass.get_instance] || Types::NILCLASS)
                elsif LaserSingletonClass === klass && klass < ClassRegistry['Range']
                  Laser.debug_puts 'specific range'
                  if element_types[klass.get_instance]  
                    resulting_choices << TupleType.new(element_types[klass.get_instance])
                  else  # invalid ranges (arr = [1, 2]; arr[-3..3]) return nil
                    resulting_choices << Types::NILCLASS
                  end
                elsif klass == ClassRegistry['Fixnum']
                  Laser.debug_puts 'unknown fixnum'
                  resulting_choices.merge(element_types)
                  resulting_choices << Types::NILCLASS
                elsif klass == ClassRegistry['Range']
                  Laser.debug_puts 'unknown range'
                  # no idea, just say "all arrays"
                  resulting_choices << Types::ARRAY
                end
              end
            end
          elsif arg_types.size == 2  # start, length
            
          else
            # error, should never reach
          end
          Types::UnionType.new(resulting_choices)
        end
        
        def raise_frequency_for_types(self_type, arg_types = [], block_type = nil)
          Frequency::NEVER
        end
        
        def raise_type_for_types(self_type, arg_types = [], block_type = nil)
          Types::EMPTY
        end
      end
    end
    
    EXPECTATIONS = {'to_s' => Types::STRING,
                    'to_str' => Types::STRING,
                    'to_i' => Types::ClassType.new('Integer', :covariant),
                    'to_int' => Types::ClassType.new('Integer', :covariant),
                    'to_f' => Types::FLOAT,
                    'to_a' => Types::ARRAY,
                    'to_ary' => Types::ARRAY,
                    '!' => Types::BOOLEAN }
  end
end
