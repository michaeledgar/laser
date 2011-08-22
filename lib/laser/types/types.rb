require 'set'
module Laser
  module Types
    # All these relations are very inefficient, but they don't show up in
    # profiling, yet.
    #
    # Subtype relation. Extremely important. Don't mess it up.
    def self.subtype?(sub, top)
      case top
      when ClassObjectType
        sub.possible_classes.all? { |sub_class| sub_class <= top.class_object }
      when ClassType
        if top.variance == :invariant
          klass = top.possible_classes.first
          sub.possible_classes.all? do |sub_class|
            if Analysis::LaserSingletonClass === sub_class
              sub_class <= klass
            else
              sub_class == klass
            end
          end
        else
          sub.possible_classes.subset?(top.possible_classes)
        end
      when UnionType
        sub.member_types.all? do |submember|
          top.member_types.any? { |topmember| subtype?(submember, topmember) }
        end
      else
        sub.possible_classes.subset?(top.possible_classes)
      end
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
        name = name.to_sym
        member_types.map { |type| type.public_matching_methods(name) }.flatten.uniq
      end

      def matching_methods(name)
        name = name.to_sym
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
          @class_object = Analysis::ClassRegistry[class_object]
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
        name = name.to_sym
        possible_classes.map do |klass|
          klass.instance_method(name) if klass.visibility_table[name] == :public
        end.compact.uniq
      end
      
      def matching_methods(name)
        name = name.to_sym
        possible_classes.map { |klass| klass.instance_method(name) }.compact.uniq
      end
      
      def possible_classes
        klass = Analysis::ClassRegistry[class_name]
        case variance
        when :invariant then ::Set[klass]
        when :covariant
          if Analysis::LaserClass === klass
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
    BOOL_OR_NIL = UnionType.new([BOOLEAN, NILCLASS])
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
        ::Set[Analysis::ClassRegistry['Array']]
      end

      def member_types
        [self]
      end
      
      def public_matching_methods(name)
        if ClassRegistry['Array'].visibility_for(name) == :public
          matching_methods(name)
        else
          Types::ARRAY.public_matching_methods(name)
        end
      end
      
      def matching_methods(name)
        name = name.to_sym
        case name
        when :[]
          [TupleIndexMethod.new(self)]
        when :to_a, :to_ary
          [TupleSelfMethod.new(self, name)]
        when :+
          [TuplePlusMethod.new(self)]
        when :*
          [TupleTimesMethod.new(self)]
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
          Analysis::ClassRegistry['Array'].instance_method(name).send(method, *args, &blk)
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
      
      class TuplePlusMethod < TupleMethod
        def name
          '+'
        end
        
        def return_type_for_types(self_type, arg_types = [], block_type = nil)
          if arg_types.first.member_types.one?
            other_type = arg_types.first.member_types.first
          end
          if Types::TupleType === other_type
            Types::TupleType.new(tuple_type.element_types + other_type.element_types)
          else
            Types::ARRAY
          end
        end
        
        def raise_frequency_for_types(self_type, arg_types = [], block_type = nil)
          Frequency::MAYBE
        end
        
        def raise_type_for_types(self_type, arg_types = [], block_type = nil)
          Types::UnionType.new([Types::ClassType.new('ArgumentError', :invariant)])
        end
      end
      
      class TupleTimesMethod < TupleMethod
        def name
          '*'
        end
        
        def return_type_for_types(self_type, arg_types = [], block_type = nil)
          resulting_choices = Set.new
          element_types = tuple_type.element_types

          arg_types[0].possible_classes.each do |klass|
            if Analysis::LaserSingletonClass === klass &&
               (klass < Analysis::ClassRegistry['Integer'] || klass < Analysis::ClassRegistry['Float'])
              factor = klass.get_instance.to_i
              if factor >= 0
                resulting_choices << TupleType.new(element_types * klass.get_instance)
              end
            elsif klass < Analysis::ClassRegistry['Numeric']
              resulting_choices << Types::ARRAY
            end
          end

          Types::UnionType.new(resulting_choices)
        end
        
        def raise_frequency_for_types(self_type, arg_types = [], block_type = nil)
          Frequency::MAYBE
        end
        
        def raise_type_for_types(self_type, arg_types = [], block_type = nil)
          Types::UnionType.new([Types::ClassType.new('ArgumentError', :invariant)])
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
            arg_types[0].possible_classes.each do |klass|
              if Analysis::LaserSingletonClass === klass && klass < Analysis::ClassRegistry['Fixnum']
                resulting_choices << (element_types[klass.get_instance] || Types::NILCLASS)
              elsif Analysis::LaserSingletonClass === klass && klass < Analysis::ClassRegistry['Range']
                if element_types[klass.get_instance]  
                  resulting_choices << TupleType.new(element_types[klass.get_instance])
                else  # invalid ranges (arr = [1, 2]; arr[-3..3]) return nil
                  resulting_choices << Types::NILCLASS
                end
              elsif klass == Analysis::ClassRegistry['Fixnum']
                resulting_choices.merge(element_types)
                resulting_choices << Types::NILCLASS
              elsif klass == Analysis::ClassRegistry['Range']
                # no idea, just say "all arrays"
                resulting_choices << Types::ARRAY
              end
            end
          elsif arg_types.size == 2  # start, length
            arg_types[0].possible_classes.each do |klass_1|
              arg_types[1].possible_classes.each do |klass_2|
                if Analysis::LaserSingletonClass === klass_1 && klass_1 < Analysis::ClassRegistry['Fixnum'] &&
                   Analysis::LaserSingletonClass === klass_2 && klass_2 < Analysis::ClassRegistry['Fixnum']
                  new_elts = element_types[klass_1.get_instance, klass_2.get_instance]
                  resulting_choices << TupleType.new(new_elts)
                end
              end
            end
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
