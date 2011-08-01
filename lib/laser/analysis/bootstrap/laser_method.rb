module Laser
  module Analysis
    # Laser representation of a method. This name is tweaked so it doesn't
    # collide with ::Method.
    class LaserMethod
      extend ModuleExtensions
      attr_reader :name, :proc, :arglist
      alias arguments arglist
      attr_accessor :body_ast, :owner, :arity

      def initialize(name, base_proc)
        @name = name
        @type_instantiations = {}
        @proc = base_proc
        @argument_annotations = nil
        if base_proc  # always true except some ugly test cases
          @arglist = base_proc.arguments
          @arity = Arity.for_arglist(@arglist)
        else
          @arglist = []
          @arity = nil
        end  
        yield self if block_given?
      end
      
      ################## Potentially Annotated Properties ######################
      
      %w(special pure builtin predictable mutation annotated_return annotated_yield_usage
         overloads annotated_raise_frequency raises).each do |attr|
        define_method(attr) do
          instance_variable_get("@#{attr}") || (self.proc ? self.proc.send(attr) : nil)
        end
        define_method("#{attr}=") do |val|
          instance_variable_set("@#{attr}", val)
        end
      end

      def overloads
        @overloads || (self.proc ? self.proc.overloads : {})
      end

      def predictable
        @predictable || (self.proc ? self.proc.predictable : true)
      end

      # Gets all annotations with the same name as an argument.
      def argument_annotations
        @argument_annotations ||=
          if @proc
            arguments.map do |arg|
              @proc.annotations[arg.name] if @proc.annotations.has_key?(arg.name)
            end.compact
          else
            []
          end
      end

      def yield_type
        return annotated_yield_usage if annotated_yield_usage
        return @yield_type if @yield_type
        if builtin
          :ignored
        else
          master_cfg.analyze(method: self)
          @yield_type = master_cfg.yield_type
        end
      end
      
      def yield_arity
        return @yield_arity if @yield_arity
        master_cfg.analyze(method: self)
        @yield_arity = master_cfg.yield_arity
      end
      
      def raise_frequency_for_types(self_type, arg_types = [], block_type = nil)
        block_type ||= Types::NILCLASS
        unless arg_types_unify_with_annotations?(arg_types)
          return Frequency::ALWAYS
        end
        return annotated_raise_frequency if annotated_raise_frequency
        return Frequency::MAYBE if builtin || special
        cfg_for_types(self_type, arg_types, block_type).raise_frequency
      end
      
      def raise_type_for_types(self_type, arg_types = [], block_type = nil)
        block_type ||= Types::NILCLASS
        Laser.debug_puts("Calculating raise type for #{owner.name}##{name} with types "+
                         "#{self_type.inspect} #{arg_types.inspect} #{block_type.inspect}")
        unless arg_types_unify_with_annotations?(arg_types)
          return ClassRegistry['TypeError'].as_type  # needs parameterization later
        end
        if raises
          Laser.debug_puts("Raise type is annotated: #{self.raises.inspect}")
          return self.raises 
        end
        if builtin || special
          if annotated_raise_frequency == Frequency::NEVER
            self.raises = Types::EMPTY
            Laser.debug_puts("Raise type is annotated: #{self.raises.inspect}")
            return self.raises
          end
          Laser.debug_puts("Builtin/special: Types::TOP")
          return Types::TOP
        end
        cfg_for_types(self_type, arg_types, block_type).raise_type
      end
      
      def return_type_for_types(self_type, arg_types = [], block_type = nil)
        block_type ||= Types::NILCLASS
        return annotated_return if annotated_return
        unless overloads.empty?
          return overload_for_arg_types(arg_types)
        end
        return Types::TOP if builtin || special
        result = cfg_for_types(self_type, arg_types, block_type).return_type
        check_return_type_against_expectations(result)
        result
      end

      def valid_arity?(num_args)
        @arity ? @arity.include?(num_args) : true
      end

      def overload_for_arg_types(arg_types)
        overloads.each do |overload_args, proc_type|
          # compatible arg count
          if overload_args.size == arg_types.size
            # all types unify?
            if overload_args.zip(arg_types).all? { |spec, concrete| Types.subtype?(concrete, spec) }
              return proc_type.subtypes[1]
            end
          end
        end
        raise TypeError.new("No overload found for #{self.inspect} with arg types #{arg_types.inspect}")
      end

      # Checks if the given argument types correctly unify with any
      # user-requested restrictions.
      def arg_types_unify_with_annotations?(arg_types)
        if argument_annotations.any?
          # Match actual arguments against formal arguments
          formal_assignments = assign_formals(arg_types)
          # Check annotations for formals against actual types
          argument_annotations.each do |note_list|
            note_list.each do |type_annotation|
              expected = type_annotation.type
              given = formal_assignments[type_annotation.name]
              # no given -> optional arg that's left out.
              return false if given && !Types.subtype?(given, expected)
            end
          end
        end
        true
      end

      def check_return_type_against_expectations(return_type)
        if (expectation = Types::EXPECTATIONS[self.name]) &&
            !Types.subtype?(return_type, expectation)
          @proc.ast_node.add_error(ImproperOverloadTypeError.new(
            "All methods named #{self.name} should return a subtype of #{expectation.inspect}",
            @proc.ast_node))
        end
      end

      def master_cfg
        @master_cfg ||= @proc.ssa_cfg.tap do |cfg|
          cfg.bind_self_type(Types::ClassType.new(owner.path, :covariant))
        end
      end
      
      def cfg_for_types(self_type, arg_types = [], block_type = nil)
        block_type ||= Types::NILCLASS
        Laser.debug_puts("Calculating CFG(#{owner.name}##{name}, #{self_type.inspect}, #{arg_types.inspect}, #{block_type.inspect})")
        @type_instantiations[[self_type, *arg_types, block_type]] ||= master_cfg.dup.tap do |cfg|
          cfg.bind_self_type(self_type)
          cfg.bind_formal_types(arg_types)
          cfg.bind_block_type(block_type)
          cfg.analyze(method: self)
        end
      end

      def simulate_with_args(new_self, args, block, opts)
        self_type = Utilities.type_for(new_self)
        formal_types = args.map { |arg| Utilities.type_for(arg) }
        block_type = Utilities.type_for(block)
        cfg_for_types(self_type, formal_types, block_type).dup.simulate(
            args, opts.merge(self: new_self,
                           method: self,
                            block: block,
                      start_block: @proc.start_block))
      end

      # Maps a sequence of objects (one per actual argument) to
      # the corresponding formal argument.
      def assign_formals(actual_objs)
        args = arguments
        result_array = []
        num_required = args.count { |arg| arg.kind == :positional }
        num_optional = actual_objs.size - num_required
        current_arg = 0
        current_actual = 0
        rest = []
        while num_required > 0 || num_optional > 0
          next_arg = args[current_arg]
          if next_arg.kind == :positional
            result_array << [next_arg.name, actual_objs[current_actual]]
            num_required -= 1
            current_actual += 1
            current_arg += 1
          elsif next_arg.kind == :optional && num_optional > 0
            result_array << [next_arg.name, actual_objs[current_actual]]
            num_optional -= 1
            current_actual += 1
            current_arg += 1
          elsif next_arg.kind == :optional && num_optional == 0
            current_arg += 1
          elsif next_arg.kind == :rest && num_optional > 0
            rest << actual_objs[current_actual]
            current_actual += 1
            num_optional -= 1
          elsif next_arg.kind == :rest
            result_array << [next_arg.name, rest]
          end
        end
        Hash[*result_array.flatten(1)]
      end

      def dup
        result = LaserMethod.new(name, proc)
        result.body_ast = self.body_ast
        result.owner = self.owner
        result.arity = self.arity
        result
      end
      
      def refine_arity(new_arity)
        return new_arity if @arity.nil?
        new_begin = [new_arity.begin, @arity.begin].min
        new_end = [new_arity.end, @arity.end].max
        new_begin..new_end
      end
    end
  end
end