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
        attr_accessor :root
        attr_reader :edge_flags

        # Initializes the control flow graph, potentially with a list of argument
        # bindings. Those bindings will almost always be extracted from parsing
        # an argument list of a method or block.
        #
        # formal_arguments: [ArgumentBinding]
        def initialize(formal_arguments = [])
          @formals = formal_arguments
          @uses = Hash.new { |hash, temp| hash[temp] = Set.new }
          @definition = {}
          @constants  = {}
          @name_stack = Hash.new { |hash, temp| hash[temp] = [] }
          @name_count = Hash.new { |hash, temp| hash[temp] = 0 }
          super()
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
        
        # Looks up the basic block (vertex) with the given name.
        def vertex_with_name(name)
          self.vertices.find { |vert| vert.name == name }
        end
        
        def save_pretty_picture(fmt='png', dotfile='graph', params = {'shape' => 'box'})
          write_to_graphic_file(fmt, dotfile, params)
        end
        
        def dotty(params = {'shape' => 'box'})
          super
        end
        
        # Runs full analysis on the CFG. Puts it in SSA then searches for warnings.
        def analyze
          static_single_assignment_form
          perform_constant_propagation
          kill_unexecuted_edges
          add_unused_variable_warnings
          perform_dead_code_discovery
        end
        
        def all_errors
          self.root.all_errors
        end
        
        # Returns the names of all variables in the graph
        def all_variables
          vertices.map(&:variables).inject(:|)
        end

        # Marks all edges that are not executable as fake edges. That way, the
        # postdominance of Exit is preserved, but dead code analysis will ignore
        # them.
        def kill_unexecuted_edges
          each_edge do |u, v|
            unless is_executable?(u, v)
              add_flag(u, v, EDGE_FAKE)
            end
          end
        end

        # Dead Code Discovery: O(|V| + |E|)!
        IGNORED_DEAD_CODE_NODES = [:@ident, :@op, :void_stmt]
        def perform_dead_code_discovery
          dfst = depth_first_spanning_tree(self.enter)
          # then, go over all code in dead blocks, and mark potentially dead
          # ast nodes.
          # O(V)
          (vertices - dfst.vertices).each do |blk|
            blk.each { |ins| ins.node.reachable = false unless ins[0] == :jump  }
          end
          # run through all reachable statements and mark those nodes, and their
          # parents, as partially executing.
          #
          # at most |V| nodes will have cur.reachable = true set.
          # at most O(V) instructions will be visited total.
          dfst.each_vertex do |blk|
            blk.instructions.each do |ins|
              cur = ins.node
              while cur
                cur.reachable = true
                cur = cur.parent
              end
            end
          end
          dfs_for_dead_code self.root
        end
        
        # Performs a simple DFS, adding errors to any nodes that are still
        # marked unreachable.
        def dfs_for_dead_code(node)
          if node.reachable
            node.children.select { |x| Sexp === x }.reject do |child|
              child == [] || child[0].is_a?(::Fixnum) || IGNORED_DEAD_CODE_NODES.include?(child.type)
            end.each do |child|
              dfs_for_dead_code(child)
            end
          else
            node.add_error DeadCodeWarning.new('Dead code', node)
          end
        end
        
        # Adds unused variable warnings to all nodes which define a variable
        # that is not used.
        def add_unused_variable_warnings
          unused_variables.reject { |var| var.name.start_with?('%') }.each do |temp|
            # TODO(adgar): KILLMESOON
            next unless @definition[temp]
            node = @definition[temp].node
            node.add_error(
                UnusedVariableWarning.new("Variable defined but not used: #{temp.non_ssa_name}", node))
          end
        end
        
        # Gets the set of unused variables. After SSA transformation, any
        # variable with uses
        def unused_variables
          all_variables - @uses.keys.select { |temp| @uses[temp].any? }
        end
      end
    end
  end
end