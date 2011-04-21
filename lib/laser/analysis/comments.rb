module Laser
  # Comment class: basic class representing a comment extracted from the tokens
  # in a Ruby token stream.
  Comment = Struct.new(:body, :line, :col) do
    def initialize(*args)
      super
      @features = nil
      @map = nil
    end

    def location
      [line, col]
    end
    
    def features
      @features ||= body.gsub(/^#+\s?/, '').scan(/^\s*.*(?:\n\s{3,}.*)*/).map(&:strip)
    end
    
    def attribute(name)
      feature = features.find { |part| part.lstrip.start_with?("#{name}:") }
      feature.lstrip[(name.size + 1) .. -1].strip if feature
    end
    
    def annotations
      parser = Parsers::AnnotationParser.new
      features.map { |feature| parser.parse(feature) }.compact
    end
    
    def annotation_map
      return @map if @map
      initial = Hash.new { |h, k| h[k] = [] }
      @map = annotations.inject(initial) { |acc, note| acc[note.name] << note; acc }
    end
  end
end