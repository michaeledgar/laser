require 'set'
class Set
  # Picks an arbitrary element from the set and returns it. Use +pop+ to
  # pick and delete simultaneously.
  def pick
    @hash.first.first
  end

  # Picks an arbitrary element from the set and deletes it. Use +pick+ to
  # pick without deletion.
  def pop
    key = pick
    @hash.delete(key)
    key
  end
end