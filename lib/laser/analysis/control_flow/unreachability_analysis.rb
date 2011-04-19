module Laser
  module SexpAnalysis
    module ControlFlow
      module UnreachabilityAnalysis
        # Dead Code Discovery: O(|V| + |E|)!
        IGNORED_DEAD_CODE_NODES = [:@ident, :@op, :void_stmt]
        def perform_dead_code_discovery(delete_dead=false)
          dfst = depth_first_spanning_tree(self.enter)

          # then, go over all code in dead blocks, and mark potentially dead
          # ast nodes.
          # O(V)
          (vertices - dfst.vertices).each do |blk|
            blk.each { |ins| ins.node.reachable = false if ins.node  }
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
          (vertices - dfst.vertices).each { |block| remove_vertex block } if delete_dead
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
      end
    end
  end
end