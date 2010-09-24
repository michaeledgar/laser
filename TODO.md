# Cleanup

* Completely remove context stack remnants

# Useful Features

* Easy, DSL-like way to specify regex-matching, token-matching for match?
* Easy, DSL-like way to specify gsub-based fix calls
* Token Matching engine. Something along the lines of being able to match: [!whitespace, whitespace?, comment] to match code, possibly some whitespace, and a comment. Could donate to YARD.
* * DFA? Simple backtracking recursion?
* * Leftmost-longest

# Useful Warnings

* Assignment in condition
* Multiline blocks with { } notation
* Never-executed code