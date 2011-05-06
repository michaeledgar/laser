require 'yaml'
module Laser
  module SexpAnalysis
    module Annotations
      extend ModuleExtensions
      # Global annotations are only run once, at the root. 
      cattr_accessor_with_default :global_annotations, []
      
      # Performs full analysis on the given inputs.
      def self.annotate_inputs(inputs, opts={})
        inputs.map! do |filename, text|
          [filename, text, Sexp.new(RipperPlus.sexp(text), filename, text)]
        end
        apply_inherited_attributes(inputs)
        perform_load_time_analysis(inputs, opts)
        inputs.map! { |filename, _, tree| [filename, tree] }
      end
      
      # Applies all the inherited attributes to the given inputs, in the
      # order specified by annotation_config.yaml
      def self.apply_inherited_attributes(inputs)
        ordered_annotations.each do |annotator|
          inputs.each do |filename, text, tree|
            Scope::GlobalScope.lookup('$"').value.unshift(filename)
            if SETTINGS[:profile]
              time = Benchmark.realtime { annotator.annotate_with_text(tree, text) }
              puts "Time spent running #{annotator.class} on #{filename}: #{time}"
            else
              annotator.annotate_with_text(tree, text)
            end
          end
        end
      end
      
      # Performs load-time analysis on the given inputs. Inherited attributes
      # must be applied at this point.
      def self.perform_load_time_analysis(inputs, opts={})
        annotator = ScopeAnnotation.new
        inputs.each do |filename, text, tree|
          if SETTINGS[:profile]
            time = Benchmark.realtime { annotator.annotate_with_text(tree, text) }
            puts "Time spent running #{annotator.class} on #{filename}: #{time}"
          else
            #annotator.annotate_with_text(tree, text)
            ControlFlow.perform_cfg_analysis(tree, text, opts)
          end
        end
      end
      
      # Returns the order that annotations should be run.
      def self.annotation_ordered
        @order ||= YAML.load_file(File.join(File.dirname(__FILE__), 'annotations', 'annotation_config.yaml'))
      end
      
      # Returns the inherited attributes in the order they are intended
      # to be run by the YAML file.
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
      extend ModuleExtensions
      include Visitor
      cattr_accessor_with_default :dependencies, []
      def self.inherited(klass)
        add_global_annotator klass
      end
      # other must be a symbol due to indeterminate load order
      # @example
      #    class AnnotatorA
      #      depends_on :AnnotatorB
      #    end
      def self.depends_on(other)
        dependencies << other
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