module Wool
  # This is the base module for all annotations that can run on ASTs.
  # It includes all other annotation modules to provide all the
  # annotations to the Sexp class. These annotations are run at initialize
  # time for the Sexps and have access to a node and all of its child nodes,
  # all of which have been annotated. Synthesized attributes are fair game,
  # and adding inherited attributes to subnodes is also fair game.
  #
  # All annotations add O(V) to the parser runtime.
  module Annotations
    # This module provides some helper methods to inject functionality into
    # the Sexp class. Since that's what an annotation is, I don't consider
    # this bad form!
    module BasicAnnotation
      def add_annotator(*args)
        SexpAnalysis::Sexp.__send__(:annotations).concat args
      end
      alias_method :add_annotators, :add_annotator
      def add_property(*args)
        SexpAnalysis::Sexp.__send__(:attr_accessor, *args)
      end
      alias_method :add_properties, :add_property
    end
    class Base
      def annotate!(sexp)
        raise NotImplementedError.new('You must provide an implementation for #annotate!')
      end
    end
  end
end

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'annotations', '**', '*.rb'))].each do |file|
  load file
end