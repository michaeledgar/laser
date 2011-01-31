module Laser
  # Comment class: basic class representing a comment extracted from the tokens
  # in a Ruby token stream.
  Comment = Struct.new(:body, :line, :col) do
    def location
      [line, col]
    end
  end
end