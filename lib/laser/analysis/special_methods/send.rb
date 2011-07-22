module Laser
  module SexpAnalysis
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

        def each_target_method(self_type, arg_type)
          arg_type.possible_classes.each do |target_klass|
            if LaserSingletonClass === target_klass
              target_method_name = target_klass.get_instance.to_s
              self_type.matching_methods(target_method_name).each do |method|
                yield(method)
              end
            end
          end
        end
        
        def collect_type_from_targets(to_call, self_type, arg_types, block_type)
          result_type = Types::UnionType.new([])
          each_target_method(self_type, arg_types[0]) do |method|
            result_type |= method.send(to_call, self_type, arg_types[1..-1], block_type)
          end
          result_type
        end

        def return_type_for_types(self_type, arg_types, block_type)
          collect_type_from_targets(:return_type_for_types, self_type, arg_types, block_type)
        end

        def raise_type_for_types(self_type, arg_types, block_type)
          collect_type_from_targets(:raise_type_for_types, self_type, arg_types, block_type)
        end

        def raise_frequency_for_types(self_type, arg_types, block_type)
          all_frequencies = []
          each_target_method(self_type, arg_types[0]) do |method|
            all_frequencies << method.raise_frequency_for_types(self_type, arg_types[1..-1], block_type)
          end
          Frequency.combine_samples(all_frequencies)
        end
      end
    end
  end
end