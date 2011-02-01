module Laser
  # Comment class: basic class representing a comment extracted from the tokens
  # in a Ruby token stream.
  Comment = Struct.new(:body, :line, :col) do
    def location
      [line, col]
    end
    
    def features
      body.gsub(/^#+\s?/, '').scan(/^\s*.*(?:\n\s{3,}.*)*/).map(&:strip)
    end
  end
end