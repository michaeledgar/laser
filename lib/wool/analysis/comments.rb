module Laser
  Comment = Struct.new(:body, :line, :col) do
    def location
      [line, col]
    end
  end
end