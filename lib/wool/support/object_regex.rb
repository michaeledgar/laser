module Wool
  # Provides general-purpose regex searching on any object implementing #reg_desc.
  # See design_docs/object_regex for the mini-paper explaining it. With any luck,
  # this will make it into Ripper so I won't have to do this here.
  class ObjectRegex
    def initialize(pattern)
      @map = generate_map(pattern)
      @pattern = generate_pattern(pattern)
    end
  
    def mapped_value(reg_desc)
      @map[reg_desc] || @map[:FAILBOAT]
    end
  
    MAPPING_CHARS = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    def generate_map(pattern)
      alphabet = pattern.scan(/[A-Za-z]+/).uniq
      repr_size = Math.log(alphabet.size + 1, MAPPING_CHARS.size).ceil
      @item_size = repr_size + 1

      map = Hash[alphabet.map.with_index do |symbol, idx|
        [symbol, mapping_for_idx(repr_size, idx)]
      end]
      map.merge!(FAILBOAT: mapping_for_idx(repr_size, map.size))
    end
  
    def mapping_for_idx(repr_size, idx)
      convert_to_mapping_radix(repr_size, idx).map do |char|
        MAPPING_CHARS[char]
      end.join + ';'
    end
  
    def convert_to_mapping_radix(repr_size, num)
      result = []
      repr_size.times do
        result.unshift(num % MAPPING_CHARS.size)
        num /= MAPPING_CHARS.size
      end
      result
    end
  
    def generate_pattern(pattern)
      replace_tokens(fix_dots(remove_ranges(pattern)))
    end
  
    def remove_ranges(pattern)
      pattern.gsub(/\[([A-Za-z ]*)\]/) do |match|
        '(?:' + match[1..-2].split(/\s+/).join('|') + ')'
      end
    end
  
    def fix_dots(pattern)
      pattern.gsub('.', '.' * (@item_size - 1) + ';')
    end
  
    def replace_tokens(pattern)
      pattern.gsub(/[A-Za-z]+/) do |match|
        '(?:' + mapped_value(match) + ')'
      end.gsub(/\s/, '')
    end
  
    def mapped_input(input)
      input.map { |object| object.reg_desc }.map { |desc| mapped_value(desc) }.join
    end
  
    def match(input, pos=0)
      new_input = mapped_input(input)
      if (match = new_input.match(@pattern, pos))
        start, stop = match.begin(0) / @item_size, match.end(0) / @item_size
        input[start...stop]
      end
    end
    
    def all_matches(input)
      new_input = mapped_input(input)
      result, pos = [], 0
      while (match = new_input.match(@pattern, pos))
        start, stop = match.begin(0) / @item_size, match.end(0) / @item_size
        result << input[start...stop]
        pos = match.end(0)
      end
      result
    end
  end
end