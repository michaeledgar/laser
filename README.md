LASER: Lexically- and Semantically-Enriched Ruby
================================================

**Homepage**:     [http://carboni.ca/projects/p/laser](http://carboni.ca/)   
**IRC**:          [irc.freenode.net / #laser](irc://irc.freenode.net/laser)     
**Git**:          [http://github.com/michaeledgar/laser](http://github.com/michaeledgar/laser)   
**Author**:       Michael Edgar    
**Copyright**:    2011   
**License**:      AGPL v3.0 w/ Commercial Exceptions. See below.    
**Latest Version**: 0.7.0pre1    
**Release Date**: None, yet.

Synopsis
--------

LASER is a tool to analyze the lexical structure and semantic meaning of your
Ruby programs. It will be able to discover bugs that Ruby only encounters at
run-time, and it can discover properties about your code that no pre-existing tools
can, such as whether a given block of code raises, which methods are private,
if a method call could require a block, and so on. It provides warnings
as well as errors for *potentially* error-prone code, such as:

    if x = 5
      # well, x is 5 *now*
    end

Naturally, all warnings can be ignored on a case-by-case basis with inline comments
and turned off completely via command-line switches.

Feature List
------------
                                                                              
Details are always forthcoming, but:

**1. Optional Type System** - taking some cues from Gilad Bracha's Strongtalk.  
**2. Style Fixing** - There are many style no-nos in Ruby. LASER can find them *and* fix them
like similar linting tools for other languages.  
**3. Common Semantic Analyses** - dead-code discovery, yield-ability, raise-ability,
unused variables/arguments, and so on.  
**4. Documentation Generation** - By this, I mean inserting comments in your code documenting
it. I don't want to try to replace YARD, which has already done tons of work in parsing docs
and generating beautiful output as a result. But LASER can definitely, say, insert a
`@raise [SystemExitError]` when it detects a call to `Kernel#exit`!    
**5. Pluggable Annotation Parsers** - to get the most out of LASER, you may wish to
annotate your code with types or arbitrary properties (such as method purity/impurity,
visibility, etc). This requires an annotation syntax, which of course will lead to religious
wars. So I'll be including the syntax *I* would like, as well as a parser for YARD-style
annotations.  
**6. Ruby 1.9+ only** - Yep, LASER will only run on Ruby 1.9, and it'll expect its target
code is Ruby 1.9. Of course, since any 1.8 code will still parse just fine, the only issues
that will come up is API differences (looking at you, `String`).  
**7. Reusable Semantic Information** - I don't want a new AST format. I don't like the one
provided by RubyParser and co. So I'm sticking with Ripper's AST format. It has quirks, but
I prefer it, and it's part of the standard library. LASER works by creating an Array subclass
called `Sexp` that wraps the results of a Ripper parse and *does not modify its contents*. So anyone
expecting a typical Ripper AST can use the results of LASER's analysis. The `Sexp` subclass then
has a variety of accessor methods created on it that contain the results of static analysis.

More to come here.

Installing
----------

To install LASER, use the following command:

    $ gem install laser --prerelease
    
(Add `sudo` if you're installing to a directory requiring root privileges to write)
                                                                              
Usage
-----

There are a couple of ways to use LASER. It has a command-line implementation,
and a Rake task.

The command-line implementation is still having its flags worked out for usability -
right now, there's some flexibility, but they're a huge pain to use. Also, the style-related
analyses are handled slightly differently from semantic analyses. So bear with me.

When analyzing for semantic issues, `require`s and `load`s are *always* followed. This
may become a command-line flag in the future, but it isn't now.

When analyzing for style issues, the file in question must be listed on the command line.

Example runs:

```
$ cat temp.rb
class Foo
  def initialize(x, *args)
    a, b = args[1..2]
  end
end
Foo.new(gets, gets)

$ laser temp.rb
4 warnings found. 0 are fixable.
================================
(stdin):3 Error (4) - Variable defined but not used: x
(stdin):3 Error (6) - LHS never assigned - defaults to nil
(stdin):3 Error (4) - Variable defined but not used: a
(stdin):3 Error (4) - Variable defined but not used: b
```

Cool! If you want to specify a set of warnings to consider, you can use the `--only` flag. And
if you want style errors to be fixed, use `--fix`. For example:

```
$ cat tempstyle.rb
x = 0
x+=10 # extra space at the end of this line   
# blank lines following


$ laser --only OperatorSpacing,ExtraBlankLinesWarning,InlineCommentSpaceWarning,ExtraWhitespaceWarning --fix tempstyle.rb
4 warnings found. 4 are fixable.
================================
tempstyle.rb:0 Extra blank lines (1) - This file has 3 blank lines at the end of it.
tempstyle.rb:2 Inline comment spacing error () - Inline comments must be exactly 2 spaces from code.
tempstyle.rb:2 Extra Whitespace (2) - The line has trailing whitespace.
tempstyle.rb:2 No operator spacing (5) - Insufficient spacing around +=

$ cat tempstyle.rb
x = 0
x += 10  # extra space at the end of this line   
# blank lines following$ (prompt)
```

What happened there is:

1. Inline comments were set to 2 spaces away from their line of code. This will be configurable in the future.
2. The `+=` operator was properly spaced.
3. The extra spaces at the end of line 2 were removed
4. The blank lines at the end of the file were removed.

Cool! Of course, all those would have happened if you just ran `laser --fix tempstyle.rb`, but I wanted to demonstrate
how to specify individual warnings. Again, that's going to have to be made a lot easier - I've experimented with giving
each warning a "short name" that gets emitted alongside the warning, but that has some discoverability issues. We'll see
where that goes.

Changelog
---------

- **Jan.26.11**: Not publicizing LASER yet, but I figure I need a first entry in
the changelog.
- **Jun.15.11**: [Thesis](http://www.cs.dartmouth.edu/reports/abstracts/TR2011-686/) published
based on Laser. License officially switching to AGPLv3 with commercial exceptions.
- **Aug.12.11**: First prerelease gem published, version 0.7.0pre1. Expect several iterations
before 0.7 is finalized, and please report all bugs! Not all Ruby code will work!

Copyright
---------

LASER &copy; 2011 by [Michael Edgar](mailto:adgar@carboni.ca).
By default, LASER is licensed under the AGPLv3;
see {file:LICENSE} for licensing details.
Alternative licensing arrangements are also possible;
contact [Michael Edgar](mailto:adgar@carboni.ca) to discuss your needs.