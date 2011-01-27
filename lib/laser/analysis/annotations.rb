require 'yaml'
module Laser
  module SexpAnalysis
    module Annotations
      extend ModuleExtensions
      # Global annotations are only run once, at the root. 
      cattr_accessor_with_default :global_annotations, []
      
      def self.annotate_inputs(inputs)
        inputs.map! { |filename, text| [filename, text, Sexp.new(Ripper.sexp(text))] }
        ordered_annotations.each do |annotator|
          inputs.each do |filename, text, tree|
            annotator.annotate_with_text(tree, text)
          end
        end
        inputs.map! { |filename, _, tree| [filename, tree] }
      end
      
      def self.annotation_ordered
        @order ||= YAML.load_file(File.join(File.dirname(__FILE__), 'annotations', 'annotation_config.yaml'))
      end
      
      def self.ordered_annotations
        annotation_ordered.map do |mod_name|
          global_annotations.select { |annotation| annotation.class.name.include?(mod_name) }.first
        end
      end
    end
    # This is the base module for all annotations that can run on ASTs.
    # It includes all other annotation modules to provide all the
    # annotations to the Sexp class. These annotations are run at initialize
    # time for the Sexps and have access to a node and all of its child nodes,
    # all of which have been annotated. Synthesized attributes are fair game,
    # and adding inherited attributes to subnodes is also fair game.
    #
    # All annotations add O(V) to the parser running time.
    #
    # This module also provides some helper methods to inject functionality into
    # the Sexp class. Since that's what an annotation is, I don't consider
    # this bad form!
    class BasicAnnotation
      def self.inherited(klass)
        add_global_annotator klass
      end
      def self.add_global_annotator(*args)
        Annotations.global_annotations.concat args.map(&:new)
      end
      def self.add_property(*args)
        SexpAnalysis::Sexp.__send__(:attr_accessor, *args)
      end
      def self.add_computed_property(name, &blk)
        SexpAnalysis::Sexp.__send__(:define_method, name, &blk)
      end
    end
  end
end

Dir[File.expand_path(File.join(File.dirname(__FILE__), 'annotations', '**', '*.rb'))].each do |file|
  load file
end