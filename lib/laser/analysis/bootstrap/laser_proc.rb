module Laser
  module Analysis
    
    class LaserProc < LaserObject
      attr_accessor :ast_node, :arguments, :cfg, :exit_block, :lexical_self
      attr_accessor :annotations, :line_number
      def initialize(arguments, ast_node, cfg = nil, callsite_block = nil)
        @ast_node = ast_node
        @arguments = arguments
        @cfg = cfg
        @callsite_block = callsite_block
        @lexical_self = @exit_block = nil
        @annotations = Hash.new { |h, k| h[k] = [] }
      end

      def start_block
        @callsite_block && @callsite_block.block_taken_successors.first
      end

      def inspect
        desc_part = "Proc:0x#{object_id.to_s(16)}@#{ast_node.file_name}"
        arg_part = "(#{arguments.map(&:name).join(', ')})"
        if ast_node.source_begin
          "#<#{desc_part}:#{ast_node.line_number}*#{arg_part}>"
        else
          "#<#{desc_part}*#{arg_part}>"
        end
      end
      alias name inspect

      def compiled_cfg
        return @cfg if @cfg
        # since this is lazily compiling, we should update cref to reflect the runtime
        # value before compiling. hackish.
        if @ast_node.scope.self_ptr != Scope::GlobalScope.self_ptr
          @ast_node.scope.lexical_target = @ast_node.scope.self_ptr.value.binding
        end
        builder = ControlFlow::GraphBuilder.new(@ast_node, @arguments, @ast_node.scope)
        @cfg = builder.build
      end

      def simulate(args, block, opts={})
        update_cfg_edges(opts) if opts[:invocation_sites]
        self_to_use = opts[:self] || @lexical_self
        cfg.simulate(args, opts.merge({self: self_to_use, block: block, start_block: start_block}))
      end

      def update_cfg_edges(opts)
        opts[:invocation_sites][self].each do |callsite|
          opts[:invocation_counts][self][callsite] += 1
          callsite_succ = callsite.successors.find do |b|
            b.name == start_block.name || b.name.include?("SSA-FIX-#{start_block.name}")
          end
          if !callsite.has_flag?(callsite_succ, RGL::ControlFlowGraph::EDGE_EXECUTABLE)
            callsite.add_flag(callsite_succ, RGL::ControlFlowGraph::EDGE_EXECUTABLE)
          else
            exit_succ = exit_block.successors.find do |b|
              b.name == start_block.name || b.name.include?("SSA-FIX-#{start_block.name}")
            end
            exit_block.add_flag(exit_succ, RGL::ControlFlowGraph::EDGE_EXECUTABLE)
          end
        end
      end
      
      def to_proc
        self
      end

      def call(*args, &blk)
        
      end

      def ssa_cfg
        @ssa_cfg ||= compiled_cfg.tap do |cfg|
          cfg.perform_dead_code_discovery(true)
          Laser.debug_puts('>>> Starting SSA Transformation <<<')
          cfg.static_single_assignment_form
          Laser.debug_puts('>>> Finished SSA Transformation <<<')
        end
      end

      def klass
        ClassRegistry['Proc']
      end
      
      %w(special pure builtin predictable mutation).each do |attr|
        define_method(attr) do
          default = attr == 'predictable'
          note = self.annotations[attr]
          which_value = note && note.first(&:literal?)
          which_value ? which_value.literal : default
        end
      end

      def annotated_return
        notes = annotations['returns']
        if notes.any?
          if notes.size > 1
            raise ArgumentError.new("Cannot have more than one 'returns' annotation")
          end
          return_type = notes.first
          if return_type.type?
            return_type.type
          else
            raise NotImplementedError.new('Literal annotated return types not implemented')
          end
        end
      end
      
      def annotated_yield_usage
        notes = annotations['yield_usage']
        if notes.any?
          if notes.size > 1
            raise ArgumentError.new("Cannot have more than one 'yield_usage' annotation")
          end
          yield_usage = notes.first
          if yield_usage.type?
            raise ArgumentError.new('yield_usage requires a literal yield usage category')
          else
            yield_usage.literal
          end
        end
      end
      
      def overloads
        Hash[*(annotations['overload'].map do |overload|
          raise ArgumentError.new('overload must be a type') unless overload.type?
          proc_type = overload.type
          unless Types::GenericType === proc_type && proc_type.base_type == Types::PROC
            raise ArgumentError.new('overload must be a function type')
          end
          [proc_type.subtypes[0].element_types, proc_type]
        end.flatten(1))]
      end
      
      def annotated_raise_frequency
        if annotations['raises'].any?
          annotations['raises'].select(&:literal?).map(&:literal).each do |literal|
            return Frequency[literal] if !literal || Symbol === literal
          end
          nil
        end
      end
      
      def raises
        if annotations['raises'].any?
          types = annotations['raises'].select(&:type?)
          if types.any?
            Types::UnionType.new(types.map { |note| note.type })
          end
        end
      end
    end
  end
end