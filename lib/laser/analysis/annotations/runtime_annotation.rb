module Laser
  module Analysis
    # This is a simple inherited attribute that specifies whether a given node
    # will be executed when at load-time or at run-time. In short, method bodies
    # and not-run blocks at the top-level are not run, and everything else is.
    #
    # The possible values of #runtime are :load, :run, or :unknown.
    class RuntimeAnnotation < BasicAnnotation
      add_property :runtime
      
      def annotate!(root)
        @current_runtime = :load
        super
      end
      
      def default_visit(node)
        node.runtime = @current_runtime
        visit_children(node)
      end
      
      def visit_with_runtime(*nodes, new_runtime)
        old_runtime, @current_runtime = @current_runtime, new_runtime
        nodes.each { |node| visit node }
      ensure
        @current_runtime = old_runtime
      end
      
      add :def do |node, name, params, body|
        default_visit(node)
        default_visit(name)
        visit_with_runtime(params, body, :run)
      end
      
      add :defs do |node, singleton, separator, name, params, body|
        default_visit(node)
        default_visit(singleton)
        default_visit(name)
        visit_with_runtime(params, body, :run)
      end
      
      add :method_add_block do |node, call, block|
        # TODO(adgar): Check if call is resolved, and if so, check if the block is in fact
        # executed immediately or stored. If we know the answer to that, we can specify :run
        # or :load for the block instead of just :unknown.
        default_visit(node)
        default_visit(call)

        if @current_runtime == :load
        then visit_with_runtime(block, :unknown)
        else default_visit block
        end
      end
    end
  end
end
