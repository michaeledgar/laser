module Laser
  module Analysis
    module SpecialMethods
      # Provides precise analysis of send methods. This is necessary for the
      # analyzer to be able to tell where to look for semantic information when
      # it encounters a call like this:
      #
      # method = unprovable_condition ? :foo : :bar
      # send(method, 1, 2, 3)
      #
      # In this case, send() will return the union of whatever foo or bar return,
      # and so on.
      #
      # This method supports both Kernel#send and Kernel#public_send.
      class SendMethod < LaserMethod
        def initialize(name, privacy)
          super(name, nil)
          @privacy = privacy
        end

        def all_target_methods(self_type, arg_type)
          collection = Set[]
          arg_type.possible_classes.each do |target_klass|
            if target_klass <= Analysis::ClassRegistry['String'] ||
               target_klass <= Analysis::ClassRegistry['Symbol']
              if LaserSingletonClass === target_klass &&
                target_method_name = target_klass.get_instance.to_s
                self_type.possible_classes.each do |self_class|
                  collection << self_class.instance_method(target_method_name)
                end
              else
                getter = @privacy == :any ? :instance_methods : :public_instance_methods
                self_type.possible_classes.each do |self_class|
                  self_class.send(getter).each do |method_name|
                    collection << self_class.instance_method(method_name)
                  end
                end
              end
            end
          end
          collection
        end

        def dispatch_results(self_type, arg_types, block_type)
          methods = all_target_methods(self_type, arg_types[0])
          cartesian = [[*arg_types[1..-1], block_type]]
          ignore_privacy = @privacy == :any
          results = DispatchResults.new
          results.add_samples_from_dispatch(methods, self_type, cartesian, ignore_privacy)
          results
        end

        def return_type_for_types(self_type, arg_types, block_type)
          if arg_types.size >= 1
            dispatch_results(self_type, arg_types, block_type).result_type
          else
            Types::EMPTY
          end
        end

        def raise_type_for_types(self_type, arg_types, block_type)
          if arg_types.size >= 1
            dispatch_results(self_type, arg_types, block_type).raise_type
          else
            Frequency::ALWAYS
          end
        end

        def raise_frequency_for_types(self_type, arg_types, block_type)
          if arg_types.size >= 1
            dispatch_results(self_type, arg_types, block_type).raise_frequency
          else
            ClassRegistry['ArgumentError'].as_type
          end
        end
      end
    end
  end
end