module Laser
  module Analysis
    module ControlFlow
      module GuaranteedSuperDetection
        def guaranteed_super_on_success?
          tree = dominator_tree
          success_block = tree[return_postdominator]
          check_block = success_block
          while check_block
            has_super = check_block.instructions.any? do |insn|
              insn.type == :super || insn.type == :super_vararg
            end
            return true if has_super
            check_block = check_block.successors.first
          end
          false
        end
      end
    end
  end
end
