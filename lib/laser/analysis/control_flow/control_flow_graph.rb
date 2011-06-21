require 'laser/third_party/rgl/adjacency'
require 'laser/third_party/rgl/transitivity'
require 'laser/third_party/rgl/dominators'
module Laser
  module SexpAnalysis
    module ControlFlow
      class ControlFlowGraph < RGL::ControlFlowGraph
        include ConstantPropagation
        include LifetimeAnalysis
        include StaticSingleAssignment
        include UnusedVariables
        include UnreachabilityAnalysis
        include AliasAnalysis
        include YieldProperties
        include MethodCallSearch
        include RaiseProperties
        include Simulation
        
        RETURN_POSTDOMINATOR_NAME = 'Return'
        YIELD_POSTDOMINATOR_NAME = 'YieldWithoutBlock'
        EXCEPTION_POSTDOMINATOR_NAME = 'UncaughtException'
        FAILURE_POSTDOMINATOR_NAME = 'Failure'

        attr_accessor :root, :block_register, :final_exception, :final_return
        attr_reader :formals, :uses, :definition, :constants, :live, :globals
        attr_reader :yield_type, :raise_type, :in_ssa, :yield_arity
        attr_reader :self_type, :formal_types, :block_type
        attr_reader :all_cached_variables
        # postdominator blocks for: all non-failed-yield exceptions, yield-failing
        # exceptions, and all failure types.
        
        # Initializes the control flow graph, potentially with a list of argument
        # bindings. Those bindings will almost always be extracted from parsing
        # an argument list of a method or block.
        #
        # formal_arguments: [ArgumentBinding]
        def initialize(formal_arguments = [])
          @in_ssa = false
          @self_type = nil
          @formal_types = nil
          @block_type = nil
          @block_register = nil
          @all_cached_variables = Set.new
          @live = Hash.new { |hash, temp| hash[temp] = Set.new }
          @constants  = {}
          @globals = Set.new
          @name_stack = Hash.new { |hash, temp| hash[temp] = [] }
          @name_count = Hash.new { |hash, temp| hash[temp] = 0 }
          @formals = formal_arguments
          @yield_type = :required
          @yield_arity = Set.new([Arity::ANY])
          @raise_type = Frequency::MAYBE
          super()
        end
        
        def dup
          copy = self.class.new
          copy.initialize_dup(self)
          copy
        end
        
        def initialize_dup(source)
          @root = source.root
          @in_ssa = source.in_ssa
          @self_type = source.self_type
          @formal_types = source.formal_types
          @block_type = source.block_type
          # we'll be duplicating temporaries, and since we need to know how
          # our source data about temps (defs, uses, constants...) corresponds
          # the duplicated temps, we'll need a hash to look them up.
          temp_lookup = { Bootstrap::VISIBILITY_STACK => Bootstrap::VISIBILITY_STACK }
          block_lookup = { source.enter => @enter, source.exit => @exit }
          insn_lookup = Hash.new
          # copy all vars defined in the body
          source.all_cached_variables.each do |k|
            copy = k.deep_dup
            temp_lookup[k] = copy
            @all_cached_variables << copy
          end
          self.block_register = temp_lookup[source.block_register]
          self.final_exception = temp_lookup[source.final_exception]
          self.final_return = temp_lookup[source.final_return]
          # copy all formals and their mapping to initial bindings
          @formals = source.formals.map do |formal|
            temp_lookup[formal] = formal.deep_dup
          end

          new_blocks = source.vertices.reject { |v| TerminalBasicBlock === v }
          new_blocks.map! do |block|
            copy = block.duplicate_for_graph_copy(temp_lookup, insn_lookup)
            block_lookup[block] = copy
            copy
          end
          
          new_blocks.each do |new_block|
            add_vertex new_block
          end
          source.each_edge do |u, v|
            add_edge(block_lookup[u], block_lookup[v], u.get_flags(v))
          end
          
          # computed stuff we shouldn't lose:
          # @globals
          # @constants
          # @live
          # @formal_map
          temp_lookup.each do |old, new|
            new.definition = insn_lookup[old.definition]
            new.uses = Set.new(old.uses.map { |insn| insn_lookup[insn] })
          end
          source.globals.each do |global|
            @globals.add temp_lookup[global]
          end
          source.constants.each do |temp, value|
            # no need to dup value, as these constants *MUST NOT* be mutated.
            @constants[temp_lookup[temp]] = value
          end
          source.live.each do |temp, blocks|
            @live[temp_lookup[temp]] = Set.new(blocks.map { |block| block_lookup[block] })
          end
          # Tiny hope this speeds anything up
          temp_lookup.clear
          block_lookup.clear
          insn_lookup.clear
          self
        end

        # Compares the graphs for equality. Relies on the basic blocks having unique
        # names to simplify isomorphism comparisons. Unfortunately this means
        # tests will have to know block names. Oh well.
        def ==(other)
          pairs = self.vertices.sort_by(&:name).zip(other.vertices.sort_by(&:name))
          (pairs.all? do |v1, v2|
            v1.name == v2.name && v1.instructions == v2.instructions
          end) && (self.edges.sort == other.edges.sort)
        end

        def save_pretty_picture(fmt='png', dotfile='graph', params = {'shape' => 'box'})
          write_to_graphic_file(fmt, dotfile, params)
        end
        
        def dotty(params = {'shape' => 'box'})
          super
        end

        def return_type
          unless (@exit.normal_predecessors & @exit.real_predecessors).empty?
            @final_return.expr_type
          end
        end
        
        def real_self_type
          @self_type || Types::TOP
        end

        def bind_self_type(new_self_type)
          @self_type = new_self_type
        end

        def real_formal_type(idx)
          (@formal_types && @formal_types[idx]) || Types::TOP
        end

        def bind_formal_types(new_formal_types)
          @formal_types = new_formal_types
        end

        def real_block_type
          @block_type || Types::BLOCK
        end

        def bind_block_type(new_block_type)
          @block_type = new_block_type
        end

        DEFAULT_ANALYSIS_OPTS = {optimize: true, simulate: true}
        # Runs full analysis on the CFG. Puts it in SSA then searches for warnings.
        def analyze(opts={})
          opts = DEFAULT_ANALYSIS_OPTS.merge(opts)
          # kill obvious dead code now.
          perform_dead_code_discovery(true)
          Laser.debug_puts('>>> Starting SSA Transformation <<<')
          static_single_assignment_form unless @in_ssa
          Laser.debug_puts('>>> Finished SSA Transformation <<<')
          if @root.type == :program
            Laser.debug_puts('>>> Starting Simulation <<<')
            begin
              simulate([], :mutation => true) if opts[:simulate]
            rescue Simulation::NonDeterminismHappened => err
              Laser.debug_puts('Note: Simulation was nondeterministic.')
            rescue Simulation::SimulationNonterminationError => err
              Laser.debug_puts('Note: Simulation was potentially nonterminating.')
            end
            Laser.debug_puts('>>> Finished Simulation <<<')
          else
            Laser.debug_puts('>>> Starting CP <<<')
            perform_constant_propagation
            Laser.debug_puts('>>> Finished CP <<<')
            if opts[:optimize]
              Laser.debug_puts('>>> Killing Unexecuted Edges <<<')
              kill_unexecuted_edges
              Laser.debug_puts('>>> Finished Killing Unexecuted Edges <<<')
              Laser.debug_puts('>>> Pruning Totally Useless Blocks <<<')
              prune_totally_useless_blocks
              Laser.debug_puts('>>> Finished Pruning Totally Useless Blocks <<<')
              Laser.debug_puts('>>> Dead Code Discovery <<<')
              perform_dead_code_discovery
              Laser.debug_puts('>>> Finished Dead Code Discovery <<<')
              Laser.debug_puts('>>> Adding Unused Variable Warnings <<<')
              add_unused_variable_warnings
              Laser.debug_puts('>>> Finished Adding Unused Variable Warnings <<<')

              if @root.type != :program
                Laser.debug_puts('>>> Determining Yield Properties <<<')
                find_yield_properties
                Laser.debug_puts('>>> Finished Determining Yield Properties <<<')
              end
              Laser.debug_puts('>>> Determining Raise Properties <<<')
              find_raise_properties
              Laser.debug_puts('>>> Finished Determining Raise Properties <<<')
            end
          end
        end
        
        def debug_dotty
          Laser.debug_dotty(self)
        end
        
        def all_errors
          self.root.all_errors
        end
        
        # Returns the names of all variables in the graph
        def all_variables
          return @all_cached_variables unless @all_cached_variables.empty?
          return @all_variables if @all_variables
          result = Set.new
          vertices.each do |vert|
            vert.variables.each do |var|
              result << var
            end
          end
          @all_variables = result
        end
        
        def var_named(name)
          all_variables.find { |x| x.name.start_with?(name) }
        end

        def return_postdominator
          vertex_with_name(RETURN_POSTDOMINATOR_NAME)
        end

        def yield_fail_postdominator
          vertex_with_name(YIELD_POSTDOMINATOR_NAME)
        end
        
        def exception_postdominator
          vertex_with_name(EXCEPTION_POSTDOMINATOR_NAME)
        end

        def all_failure_postdominator
          vertex_with_name(FAILURE_POSTDOMINATOR_NAME)
        end
        
        # Yields reachable vertices via depth-first-search on real edges
        def reachable_vertices
          vertices = Set[]
          worklist = Set[self.enter]
          while worklist.any?
            block = worklist.pop
            yield block if block_given?
            block.real_successors.each do |succ|
              worklist.add(succ) if vertices.add?(succ)
            end
          end
          vertices
        end
        
        # Computes the variables reachable by DFSing the start node.
        # This excludes variables defined in dead code.
        def reachable_variables(block = @enter, visited = Set.new)
          visited << block
          block.real_successors.inject(block.variables) do |cur, succ|
            if visited.include?(succ)
              cur
            else
              cur | reachable_variables(succ, visited)
            end
          end
        end

        # Removes blocks that are not reachable and which go nowhere: they
        # have no effect on the program.
        def prune_totally_useless_blocks
          vertices = self.to_a
          vertices.each do |vertex|
            if degree(vertex).zero?
              remove_vertex(vertex)
            end
          end
        end

        def prune_unexecuted_blocks
          kill_unexecuted_edges(true)  # be ruthless
          unreachable_vertices.each do |block|
            block.instructions.each do |insn|
              insn.operands.each { |op| op.uses -= ::Set[insn] }
            end
            remove_vertex block
          end
        end

        # Marks all edges that are not executable as fake edges. That way, the
        # postdominance of Exit is preserved, but dead code analysis will ignore
        # them.
        def kill_unexecuted_edges(remove=false)
          killable = Set.new
          each_edge do |u, v|
            if !(is_executable?(u, v) || is_fake?(u, v))
              killable << [u, v]
            end
          end
          killable.each do |u, v|
            if remove
              remove_edge(u, v)
            else
              u.add_flag(v, EDGE_FAKE)
            end
          end
        end

      end
    end
  end
end
