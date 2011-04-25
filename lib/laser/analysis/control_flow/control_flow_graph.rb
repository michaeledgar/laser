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
        include YieldProperties
        include RaiseProperties
        
        YIELD_POSTDOMINATOR_NAME = 'YieldWithoutBlock'
        EXCEPTION_POSTDOMINATOR_NAME = 'UncaughtException'
        FAILURE_POSTDOMINATOR_NAME = 'Failure'

        attr_accessor :root
        attr_reader :formals, :uses, :definition, :constants, :live, :globals, :formal_map
        attr_reader :yield_type, :raise_type
        # postdominator blocks for: all non-failed-yield exceptions, yield-failing
        # exceptions, and all failure types.
        
        # Initializes the control flow graph, potentially with a list of argument
        # bindings. Those bindings will almost always be extracted from parsing
        # an argument list of a method or block.
        #
        # formal_arguments: [ArgumentBinding]
        def initialize(formal_arguments = [])
          @uses = Hash.new { |hash, temp| hash[temp] = Set.new }
          @live = Hash.new { |hash, temp| hash[temp] = Set.new }
          @definition = {}
          @constants  = {}
          @globals = Set.new
          @name_stack = Hash.new { |hash, temp| hash[temp] = [] }
          @name_count = Hash.new { |hash, temp| hash[temp] = 0 }
          @formals = formal_arguments
          @formal_map = {}
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
          # we'll be duplicating temporaries, and since we need to know how
          # our source data about temps (defs, uses, constants...) corresponds
          # the duplicated temps, we'll need a hash to look them up.
          temp_lookup = Hash.new
          block_lookup = { source.enter => @enter, source.exit => @exit }
          insn_lookup = Hash.new
          # copy all vars defined in the body
          source.definition.each_key do |k|
            temp_lookup[k] = k.deep_dup
          end
          # copy all formals and their mapping to initial bindings
          @formals = source.formals.map do |formal|
            copy = formal.deep_dup
            temp_lookup[formal] = copy
            @formal_map[copy] = temp_lookup[source.formal_map[formal]]
            copy
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
          # @definition
          # @uses
          # @globals
          # @constants
          # @live
          # @formal_map
          
          source.definition.each do |temp, def_insn|
            @definition[temp_lookup[temp]] = insn_lookup[def_insn]
          end
          source.uses.each do |temp, insns|
            @uses[temp_lookup[temp]] = Set.new(insns.map { |insn| insn_lookup[insn] })
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
        
        # Runs full analysis on the CFG. Puts it in SSA then searches for warnings.
        def analyze
          # kill obvious dead code now.
          perform_dead_code_discovery(true)
          static_single_assignment_form
          
          perform_constant_propagation
          kill_unexecuted_edges
          prune_totally_useless_blocks
          perform_dead_code_discovery
          add_unused_variable_warnings
          # Don't need these anymore
          prune_unexecuted_blocks

          find_yield_properties if @root.type != :program
          find_raise_properties
        end
        
        def all_errors
          self.root.all_errors
        end
        
        # Returns the names of all variables in the graph
        def all_variables
          vertices.map(&:variables).inject(:|)
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
              insn.operands.each { |op| @uses[op] -= ::Set[insn] }
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