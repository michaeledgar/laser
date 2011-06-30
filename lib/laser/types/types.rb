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
        member_types.map { |type| type.public_matching_methods(name) }.flatten
      end

      def matching_methods(name)
        name = name.to_s
        member_types.map { |type| type.matching_methods(name) }.flatten
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
    STRING = ClassType.new('String', :invariant)
    FIXNUM = ClassType.new('Fixnum', :invariant)
    BIGNUM = ClassType.new('Bignum', :invariant)
    FLOAT = ClassType.new('Float', :invariant)
    ARRAY = ClassType.new('Array', :invariant)
    HASH = ClassType.new('Hash', :invariant)
    PROC = ClassType.new('Proc', :invariant)
    NILCLASS = ClassType.new('NilClass', :invariant)
    TRUECLASS = ClassType.new('TrueClass', :invariant)
    FALSECLASS = ClassType.new('FalseClass', :invariant)
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
      
      def signature
        {element_types: element_types}
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
