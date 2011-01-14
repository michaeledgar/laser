module Wool
  # This module provides other modules the ability to add advice
  # to methods. This module makes use of these functions opt-in.
  module Advice
    def advice_counter
      @advice_counter ||= 0
    end

    def bump_advice_counter!
      @advice_counter += 1
    end

    def before_advice(meth, advice)
      with_advice(meth, before: proc { send(advice) })
    end

    def after_advice(meth, advice)
      with_advice(meth, after: proc { send(advice) })
    end

    def argument_advice(meth, argument_tweaker)
      with_advice(meth, args: argument_tweaker)
    end

    def with_advice(meth, settings)
      counter = advice_counter
      alias_method "#{meth}_old#{counter}".to_sym, meth
      define_method meth do |*args|
        identity = proc {|*x| x}
        instance_eval(&(settings[:before] || identity))
        if settings[:args]
          new_args = instance_eval(& proc { send(settings[:args], *args)})
        end
        result = send("#{meth}_old#{counter}", *new_args)
        instance_eval(&(settings[:after] || identity))

        result
      end
      bump_advice_counter!
    end
  end
end