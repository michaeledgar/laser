module Laser
  module Analysis
    # Collects the results of attempted dispatches and calculates the return type,
    # raise type, and raise frequency.
    #
    # Is used whenever a dispatch is discovered that needs analysis. This
    # includes, for example, performing CPA and analyzing a call to send/public_send.
    #
    # Is responsible for noting that a method has been used, as this is the central
    # place for the logic pertaining to success/failure on dispatch. Keep in mind:
    # a method isn't used if it is called with incorrect arity, and that arity
    # checking should occur here.
    class DispatchResults
      ArityError = Struct.new(:receiver_class, :method_name, :provided, :expected)
      ArityError.class_eval do
        def message
          "#{receiver_class.name}##{method_name} expects " +
          "#{expected} arguments, got #{provided}."
        end
      end

      PrivacyError = Struct.new(:receiver_class, :method_name)
      PrivacyError.class_eval do
        def message
          "Tried to call #{receiver_class.privacy_for(method_name)} method " +
          "#{receiver_class.name}##{method_name}."
        end
      end

      attr_reader :result_type

      def initialize
        @raise_type  = Types::EMPTY
        @result_type = Types::EMPTY
        @privacy_failures = 0
        @privacy_samples  = 0
        @privacy_errors   = Set[]
        @arity_failures   = 0
        @arity_samples    = 0
        @arity_errors     = Set[]
        @normal_failures  = 0
        @normal_samples   = 0
      end

      def add_samples_from_dispatch(methods, self_type, cartesian, ignore_privacy)
        if methods.empty?
          @privacy_failures += 1
          @privacy_samples += 1
          @raise_type |= ClassRegistry['NoMethodError'].as_type
        end
        methods.each do |method|
          next unless check_privacy(method, self_type, ignore_privacy)
          cartesian.each do |*type_list, block_type|
            next unless check_arity(method, self_type, type_list.size)
            method.been_used!
            normal_dispatch(method, self_type, cartesian)
          end
        end
      end

      def check_privacy(method, self_type, ignore_privacy)
        result = false
        if ignore_privacy
          passes_privacy
          result = true
        else
          self_type.possible_classes.each do |self_class|
            if self_class.visibility_for(method.name) == :public
              passes_privacy
              result = true
            else
              fails_privacy(self_class, method.name)
            end
          end
        end
        result
      end

      def check_arity(method, self_type, proposed_arity)
        result = false
        self_type.possible_classes.each do |self_class|
          if method.valid_arity?(proposed_arity)
            passes_arity
            result = true
          else
            fails_arity(self_class, method.name, proposed_arity, method.arity)
          end
        end
        result
      end

      def normal_dispatch(method, self_type, cartesian)
        cartesian.each do |*type_list, block_type|
          raise_frequency = method.raise_frequency_for_types(self_type, type_list, block_type)
          if raise_frequency > Frequency::NEVER
            fails_dispatch(method.raise_type_for_types(self_type, type_list, block_type))
          end
          if raise_frequency < Frequency::ALWAYS
            passes_dispatch(method.return_type_for_types(self_type, type_list, block_type))
          end
        end
      end

      ########## Result Accessors ##############

      def raise_type
        if @privacy_samples.zero?
          ClassRegistry['NoMethodError'].as_type
        else
          @raise_type
        end
      end

      def raise_frequency
        if @privacy_samples.zero?
          Frequency::ALWAYS
        else
          [arity_failure_frequency, privacy_failure_frequency,
           normal_failure_frequency].max
        end
      end

      ############ Arity-related dispatch issues ############
      def arity_failure_frequency
        if @arity_failures == 0
          Frequency::NEVER
        elsif @arity_failures == @arity_samples
          Frequency::ALWAYS
        else
          Frequency::MAYBE
        end
      end

      def passes_arity
        @arity_samples += 1
      end

      def fails_arity(receiver_class, method_name, provided, expected)
        @arity_errors << ArityError.new(receiver_class, method_name, provided, expected)
        @arity_samples += 1
        @arity_failures += 1
        @raise_type |= ClassRegistry['ArgumentError'].as_type
      end

      ########## Privacy-related dispatch issues ############

      def privacy_failure_frequency
        if @privacy_failures == 0
          Frequency::NEVER
        elsif @privacy_failures == @privacy_samples
          Frequency::ALWAYS
        else
          Frequency::MAYBE
        end
      end

      def passes_privacy
        @privacy_samples += 1
      end

      def fails_privacy(receiver_class, method_name)
        @privacy_errors << PrivacyError.new(receiver_class, method_name)
        @privacy_samples += 1
        @privacy_failures += 1
        @raise_type |= ClassRegistry['NoMethodError'].as_type
      end

      ######### Calculated dispatch issues ###########

      def normal_failure_frequency
        if @normal_failures == 0
          Frequency::NEVER
        elsif @normal_failures == @normal_samples
          Frequency::ALWAYS
        else
          Frequency::MAYBE
        end
      end

      def passes_dispatch(return_type)
        @result_type |= return_type
        @normal_samples += 1
      end

      def fails_dispatch(raise_type)
        @raise_type |= raise_type
        @normal_failures += 1
        @normal_samples += 1
      end
    end
  end
end