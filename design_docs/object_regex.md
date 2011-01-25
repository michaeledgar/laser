## Introduction

I present a small Ruby class which provides full Ruby Regexp matching on sequences of (potentially) heterogenous objects, conditioned on those objects implementing a single, no-argument method returning a String. I propose it should be used to implement the desired behavior in the Ruby standard library.

## Motivation

So I'm hammering away at [Wool (soon to be renamed Laser)](http://github.com/michaeledgar/wool/), and I come across a situation: I need to parse out comments using Ripper's output.

I decided a while ago I wouldn't use [YARD](http://yardoc.org/)'s Ripper-based parser as it returns [its own AST format](https://github.com/lsegal/yard/blob/master/lib/yard/parser/ruby/ruby_parser.rb). YARD has its own goals, so it's not surprising the standard output from Ripper was insufficient. However, I don't want to define a new AST format - we already have Ripper's, YARD's, and of course, the venerable [RubyParser/ParseTree format](http://parsetree.rubyforge.org/). I'm rambling: the point is, I'm using exact Ripper output, and there's no existing code to annotate a Ripper node with the comments immediately preceding it.

## Extracting Comments from Ruby

Since Ripper strips the comments out when you use `Ripper.sexp`, and I'm not going to switch to the SAX-model of parsing just for comments, I had to use `Ripper.lex` to grab the comments. I immediately found this would prove annoying:

{{{
  pp Ripper.lex("  # some comment\n  # another comment\n def abc; end")
}}}

gives

{{{
 [[[1, 0], :on_sp, "  "],
  [[1, 2], :on_comment, "# some comment\n"],
  [[2, 0], :on_sp, "  "],
  [[2, 2], :on_comment, "# another comment\n"],
  [[3, 0], :on_sp, " "],
  [[3, 1], :on_kw, "def"],
  [[3, 4], :on_sp, " "],
  [[3, 5], :on_ident, "abc"],
  [[3, 8], :on_semicolon, ";"],
  [[3, 9], :on_sp, " "],
  [[3, 10], :on_kw, "end"]]
}}}

Naturally, Ripper is separating each line-comment into its own token, even those that follow on subsequent lines. I'd have to combine those comment tokens to get what a typical programmer considers one logical comment.

I didn't want to write an ugly, imperative algorithm to do this: part of the beauty of writing Ruby is you don't often have to actually write a `while` loop. I described my frustration to my roommate, and he quickly observed the obvious connection to regular expressions. That's when I remembered [Ripper.slice and Ripper.token_match](http://ruby-doc.org/ruby-1.9/classes/Ripper.html#M001274) (token_match is undocumented), which provide almost exactly what I needed:

{{{
 Ripper.slice("  # some comment\n  # another comment\n def abc; end",
              'comment (sp? comment)*')
 # => "# some comment\n  # another comment\n"
}}}

A few problems: `Ripper.slice` lexes its input on each invocation and then searches it from the start for one match. I need *all* matches. `Ripper.slice` also returns the exact string, and not the location in the source text of the match, which I need - how else will I know where the comments are? The lexer output includes line and column locations, so it should be easy to retrieve.

All this means an O(N) solution was not in sight using the built-in library functions. I was about to start doing some subclassing hacks, until I peeked at the source for `Ripper.slice` and saw it was too cool to not generalize.

## Formal Origins of `Ripper.slice`

The core of regular expressions - the [actually "regular" kind](http://en.wikipedia.org/wiki/Regular_expression#Definition) - correspond directly to a [DFA](http://en.wikipedia.org/wiki/Deterministic_finite_automata) with an [alphabet](http://en.wikipedia.org/wiki/Alphabet_\(computer_science\)) equal to the character set being searched. Naturally, Ruby's `Regexp` engine offers many features that cannot be directly described by a DFA. Anyway, what I wanted was a way to perform the same searches, only with an alphabet of token types instead of characters.

We could construct a separate DFA engine for searching sequences of our new alphabet, but we'd much rather piggyback an existing (and more-featured) implementation. Since the set of token types is countable, one can create a one-to-one mapping from token types to finite strings of an alphabet that Ruby's `Regexp` class can search, namely regular old characters. If we replace each occurrence of a member of our alphabet with a member of the target, Regexp alphabet, then we should be able to use Regexp to do regex searching on our token sequence. That transformation on the token sequence is easy: just map each token's type onto some string using a 1-to-1 function. However, one important bit that remains is how the search pattern is specified. As you saw above, we used:

{{{
 'comment (sp? comment)*'
}}}
 
to specify a search for "a comment token, followed by zero or more groups, where each group is an optional space token followed by a comment token." This departs from traditional Regexp syntax, because our alphabet is no longer composed of individual characters, it is composed of tokens. For this implementation's sake, we can observe that we require whitespace be insensitive, and that `?` and `*` operators apply to tokens, not to characters. We could specify this input however we like, as long as we can generate the correct string-searching pattern from it.

One last observation that allows us to use Regexp to search our tokens: we must be able to specify a one-to-one function from a token name to the set of tokens that it should match. In other words, no two tokens that we consider "different" can have the same token type. For a normal Regex, this is a trivial condition, as a character matches only that character. However, 'comment' must match the infinite set of all comment tokens. If we satisfy that condition, then there exists a function from a regex on token-types to a regex on strings. This is still pretty trivial to show for tokens, but later when we generalize this approach further, it becomes even more important to do correctly.

## Implementation

So, we get to Ripper's implementation:

1. Each token type is mapped to a single character in the set [a-zA-Z0-9].
2. The sequence of tokens to be searched is transformed into the sequence of characters corresponding to the token types.
3. The search pattern is transformed into a pattern that can search this mapped representation of the token sequence. Each token found in the search pattern is replaced by its corresponding single character, and whitespace is removed.
4. The new pattern runs on the mapped sequence. The result, if successful, is the start and end locations of the match in the mapped sequence.
5. Since each character in the mapped sequence corresponds to a single token, we can index into the original token sequence using the exact boundaries of the match result.

## An Example

Let's run through the previous example:

### Each token type is mapped to a single character in the set:

Ripper runs this code at load-time:

{{{
 seed = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
 SCANNER_EVENT_TABLE.each do |ev, |
   raise CompileError, "[RIPPER FATAL] too many system token" if seed.empty?
   MAP[ev.to_s.sub(/\Aon_/,'')] = seed.shift
 end
}}}

I fired up an `irb` instance and checked the result:

{{{
 Ripper::TokenPattern::MAP
 # => {"CHAR"=>"a", "__end__"=>"b", "backref"=>"c", "backtick"=>"d",
       "comma"=>"e", "comment"=>"f", "const"=>"g", "cvar"=>"h", "embdoc"=>"i",
       "embdoc_beg"=>"j", "embdoc_end"=>"k", "embexpr_beg"=>"l",
       "embexpr_end"=>"m", "embvar"=>"n", "float"=>"o", "gvar"=>"p",
       "heredoc_beg"=>"q", "heredoc_end"=>"r", "ident"=>"s", "ignored_nl"=>"t",
       "int"=>"u", "ivar"=>"v", "kw"=>"w", "label"=>"x", "lbrace"=>"y",
       "lbracket"=>"z", "lparen"=>"A", "nl"=>"B", "op"=>"C", "period"=>"D",
       "qwords_beg"=>"E", "rbrace"=>"F", "rbracket"=>"G", "regexp_beg"=>"H",
       "regexp_end"=>"I", "rparen"=>"J", "semicolon"=>"K", "sp"=>"L",
       "symbeg"=>"M", "tlambda"=>"N", "tlambeg"=>"O", "tstring_beg"=>"P",
       "tstring_content"=>"Q", "tstring_end"=>"R", "words_beg"=>"S",
       "words_sep"=>"T"}
}}}

This is completely implementation-dependent, but these characters are an implementation detail for the algorithm anyway.

### The sequence of tokens to be searched is transformed into the sequence of characters corresponding to the token types.

Ripper implements this as follows:

{{{
 def map_tokens(tokens)
   tokens.map {|pos,type,str| map_token(type.to_s.sub(/\Aon_/,'')) }.join
 end
}}}

Running this on our token stream before (markdown doesn't support anchors, so scroll up if necessary), we get this:

{{{
 "LfLfLwLsKLw"
}}}
 
This is what we will eventually run our modified Regexp against.

### The search pattern is transformed into a pattern that can search this mapped representation of the token sequence. Each token found in the search pattern is replaced by its corresponding single character, and whitespace is removed.

What we want is `comment (sp? comment)*`. In this mapped representation, a quick look at the table above shows the regex we need is 

{{{
  /f(L?f)*/
}}}

Ripper implements this in a somewhat roundabout fashion, as it seems they wanted to experiment with slightly different syntax. Since my implementation (which I'll present shortly) does not retain these syntax changes, I choose not to list the Ripper version here.

### The new pattern runs on the mapped sequence. The result, if successful, is the start and end locations of the match in the mapped sequence.

We run `/f(L?f)*/` on `"LfLfLwLsKLw"`. It matches `fLf` at position 1.

As expected, the implementation is quite simple for Ripper:

{{{
 def match_list(tokens)
   if m = @re.match(map_tokens(tokens))
   then MatchData.new(tokens, m)
   else nil
   end
 end
}}}

### Since each character in the mapped sequence corresponds to a single token, we can index into the original token sequence using the exact boundaries of the match result.

The boundaries returned were `(1..4]` in mathematical notation, or `(1...4)`/`(1..3)` as Ruby ranges. We then use this range on the original sequence, which returns:

{{{
 [[[1, 2], :on_comment, "# some comment\n"],
  [[2, 0], :on_sp, "  "],
  [[2, 2], :on_comment, "# another comment\n"]]
}}}

The implementation is again quite simple in Ripper, yet it for some reason immediately extracts the token contents:

{{{
 def match(n = 0)
   return [] unless @match
   @tokens[@match.begin(n)...@match.end(n)].map {|pos,type,str| str }
 end
}}}

## Generalization

My only complaints with Ripper's implementation, for what it intends to do, is that it lacks an API to get more than just the source code corresponding to the matched tokens. That's an API problem, and could easily be worked around.

What has been provided can be generalized, however, to work on not just tokens but sequences arbitrary, even heterogenous objects. There are a couple of properties we'll need to preserve to extend this to arbitrary sequences.

1. Alphabet Size: The alphabet for Ruby tokens is smaller than 62 elements, so we could use a single character from [A-Za-z0-9] to represent a token. If your alphabet is larger than that, we'll likely need to use a larger string for each element in the alphabet. Also, with Ruby Tokens, we knew the entire alphabet ahead of time. We don't necessarily know the whole alphabet for arbitrary sequences.
2. No two elements of the sequence which should match differently can have the same string representation. We used token types for this before, but our sequence was homogenous.

One observation makes the alphabet size issue less important: we actually only need to define a string mapping for elements in the alphabet that appear in the search pattern, not all those in the searched sequence. We can use the same string mapping for all elements in the searched sequence that don't appear in the regex pattern. If we recall that Regex features like character classes (`\w`, `\s`) and ranges (`[A-Za-z]`) are just syntactic sugar for repeated `|` operators, we'll see that in a normal regex we also only need to consider the elements of the alphabet appearing in the search pattern. All this means that if we use the same 62 characters that Ripper does, that only an input pattern with 62 different element types will require more than 1 character per element.

That said, we'll implement support for large alphabets anyway.

## General Implementation

For lack of a better name, we'll call this an `ObjectRegex`.

The full listing follows. You'll quickly notice that I haven't yet implemented the API that I actually need for Wool. Keeping focused seems incompatible with curiosity in my case, unfortunately.

{{{
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
 
   def match(input)
     new_input = input.map { |object| object.reg_desc }.
                       map { |desc| mapped_value(desc) }.join
     if (match = new_input.match(@pattern))
       start, stop = match.begin(0) / @item_size, match.end(0) / @item_size
       input[start...stop]
     end
   end
 end
}}}

## Generalized Map Generation

Generating the map is the primary interest here, so I'll start there.

First, we discover the alphabet by extracting all matches for `/[A-Za-z]+/` from the input pattern.

{{{
 alphabet = pattern.scan(/[A-Za-z]+/).uniq
}}}

We figure out how many characters we need to represent that many elements, and save that for later:

{{{
 # alphabet.size + 1 because of the catch-all, "not-in-pattern" mapping
 repr_size = Math.log(alphabet.size + 1, MAPPING_CHARS.size).ceil
 # repr_size + 1 because we will be inserting a terminator in a moment
 @item_size = repr_size + 1
}}}

Now, we just calculate the [symbol, mapped\_symbol] pairs for each symbol in the input alphabet:

{{{
 map = Hash[alphabet.map.with_index do |symbol, idx|
   [symbol, mapping_for_idx(repr_size, idx)]
 end]
}}}

We'll come back to how this works, but we must add the catch-all map entry: the entry that is triggered if we see a token in the searched sequence that didn't appear in the search pattern:

{{{
 map.merge!(FAILBOAT: mapping_for_idx(repr_size, map.size))
}}}

Note that we avoid the use of the `inject({})` idiom common for constructing Hashes, since the computation of each tuple is independent from the others. `mapping_for_idx` is responsible for finding the mapped string for the given element. In Ripper, this was just an index into an array. However, if we want more than 62 possible elements in our alphabet, we instead need to convert the index into a base-62 number, first. `convert_to_mapping_radix` does this, using the size of the `MAPPING_CHARS` constant as the new radix:

{{{
 # Standard radix conversion.
 def convert_to_mapping_radix(repr_size, num)
   result = []
   repr_size.times do
     result.unshift(num % MAPPING_CHARS.size)
     num /= MAPPING_CHARS.size
   end
   result
 end
}}}

If MAPPING\_CHARS.size = 62, then:

{{{
 convert_to_mapping_radix(3, 12498)
 # => [3, 15, 36]
}}}

After we convert each number into the necessary radix, we can then convert that array of place-value integers into a string by mapping each place value to its corresponding character in the MAPPING\_CHARS array:

{{{
 def mapping_for_idx(repr_size, idx)
   convert_to_mapping_radix(repr_size, idx).map { |char| MAPPING_CHARS[char] }.join + ';'
 end
}}}

Notice that we added a semicolon at the end there. The choice of semicolon was arbitrary - it could be any valid character that isn't in MAPPING\_CHARS. Why'd I add that?

Imagine we were searching for a long input sequence that needed 2 characters per element in the alphabet. Perhaps the Ruby grammar has expanded and now has well over 62 token types, and `comment` tokens are represented as `ba`, while `sp` tokens are `aa`. If we search for `:sp` in the input `[:comment, :sp]`, we'll search in the string `"baaa"`. it will match halfway through the `comment` token at index 1, instead of at index 2, where the `:sp` actually lies. Thus, to avoid this, we simply pad each mapping with a semicolon. We could choose to only add the semicolon if `repr_size > 1` as an optimization, if we'd like.

## Generalized Pattern Transformation

After building the new map, constructing the corresponding search pattern is quite simple:

{{{
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
}}}

First, we have to account for this regex syntax:

{{{
 [comment embdoc_beg int]
}}}

which we assume to mean "comment or eof or int", much like `[Acf]` means "A or c or f". Since constructs such as `A-Z` don't make sense with an arbitrary alphabet, we don't need to concern ourselves with that syntax. However, if we simply replace "comment" with its mapped string, and do the same with eof and int, we get something like this:

{{{
 [f;j;u;]
}}}

which won't work: it'll match any semicolon! So we manually replace all instances of `[tok1 tok2 ... tokn]` with `tok1|tok2|...|tokn`. A simple gsub does the trick, since nested ranges don't really make much sense. This is implemented in #remove\_ranges:

{{{
 def remove_ranges(pattern)
   pattern.gsub(/\[([A-Za-z ]*)\]/) do |match|
     '(?:' + match[1..-2].split(/\s+/).join('|') + ')'
   end
 end
}}}

Next, we replace the '.' matcher with a sequence of dots equal to the size of our token mapping, followed by a semicolon: this is how we properly match "any alphabet element" in our mapped form.

{{{
 def fix_dots(pattern)
   pattern.gsub('.', '.' * (@item_size - 1) + ';')
 end
}}}

Then, we simply replace each alphabet element with its mapped value. Since those mapped values could be more than one character, we must group them for other Regex features such as `+` or `*` to work properly; since we may want to extract subexpressions, we must make the group we introduce here non-capturing. Then we just strip whitespace.

{{{
 def replace_tokens(pattern)
   pattern.gsub(/[A-Za-z]+/) do |match|
     '(?:' + mapped_value(match) + ')'
   end.gsub(/\s/, '')
 end
}}}

## Generalized Matching

Lastly, we have a simple #match method:

{{{
 def match(input)
   new_input = input.map { |object| object.reg_desc }.map { |desc| mapped_value(desc) }.join
   if (match = new_input.match(@pattern))
     start, stop = match.begin(0) / @item_size, match.end(0) / @item_size
     input[start...stop]
   end
 end
}}}

While there's many ways of extracting results from a Regex match, here we do the simplest: return the subsequence of the original sequence that matches first (using the usual leftmost, longest rule of course). Here comes the one part where you have to modify the objects that are in the sequence: in the first line, you'll see:

{{{
 input.map { |object| object.reg_desc }.map { |desc| mapped_value(desc) }
}}}

This interrogates each object for its string representation: the string you typed into your search pattern if you wanted to find it. The method name (`reg_desc` in this case) is arbitrary, and this could also be implemented by providing a `Proc` to the ObjectRegex at initialization, and having the Proc be responsible for determining string representations.

We also see on the 3rd and 4th lines of the method why we stored @item\_size earlier: for boundary calculations:

{{{
 start, stop = match.begin(0) / @item_size, match.end(0) / @item_size
 input[start...stop]
}}}
 
Sometimes I wish `begin` and `end` could be local variable names in Ruby. Alas.

## Conclusion

Firstly, I won't suggest this idea is new, since DFAs with arbitrary alphabets have been around for, well, a while. Additionally, I've found a [Python library, RXPY](http://www.acooke.org/rxpy/), with a similar capability, though it's part of a larger Regex testbed library.

I've tested this both with tokens and integers (in word form) as the alphabets, with 1- and 2-character mappings. I think this technique could see use in other areas, so I'll be packaging it up as a small gem. I also think this implementation is fine for use in Ripper to achieve the tasks the existing, experimental code seeks to implement without dependence on the number of tokens in the language. A bit of optimization for the exceedingly common 1-character use-case could further support this goal.