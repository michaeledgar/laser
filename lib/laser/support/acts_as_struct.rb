module Laser
  # Lets a class act as a struct by extending the module and using acts_as_struct.
  # This is useful if you need to inherit from another class so you can't subclass
  # Struct.new. However, reads will be slower due to optimizations that the C version
  # of Struct that comes with the standard library can do.
  module ActsAsStruct
    # Mixes in struct behavior to the current class.
    def acts_as_struct(*members)
      include Comparable
      extend InheritedAttributes
      class_inheritable_array :current_members unless respond_to?(:current_members)
      
      self.current_members ||= []
      self.current_members.concat members
      all_members = self.current_members
      # Only add new members
      attr_accessor *members
      # NOT backwards compatible with a Struct's initializer. If you
      # try to initialize the first argument to a Hash and don't provide
      # other arguments, you trigger the hash extraction initializer instead
      # of the positional initializer. That's a bad idea.
      define_method :initialize do |*args|
        if args.size == 1 && Hash === args.first
          initialize_hash(args.first)
        else
          if args.size > all_members.size
            raise ArgumentError.new("#{self.class} has #{all_members.size} members " +
                                    "- you provided #{args.size}")
          end
          initialize_positional(args)
        end
      end
      
      # Initializes by treating the input as key-value assignments.
      define_method :initialize_hash do |hash|
        hash.each { |k, v| send("#{k}=", v) }
      end
      private :initialize_hash
      
      # Initialize by treating the input as positional arguments that
      # line up with the struct members provided to acts_as_struct.
      define_method :initialize_positional do |args|
        args.each_with_index do |value, idx|
          key = all_members[idx]
          send("#{key}=", value)
        end
      end
      private :initialize_positional
      
      # Helper methods for keys/values.
      define_method(:keys_and_values) { keys.zip(values) }
      define_method(:values) { keys.map { |member| send member } }
      define_method(:keys) { all_members }
      define_method(:each) { |&blk| keys_and_values.each { |k, v| blk.call([k, v]) } }
      define_method(:'<=>') do |other|
        each do |key, value|
          res = (value <=> other.send(key))
          if res != 0
            return res
          end
        end
        0
      end
    end
  end
end
