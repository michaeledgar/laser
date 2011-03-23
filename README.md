LASER: Lexically- and Semantically-Enriched Ruby
================================================

**Homepage**:     [http://carboni.ca/projects/p/laser](http://carboni.ca/)   
**IRC**:          [irc.freenode.net / #laser](irc://irc.freenode.net/laser)     
**Git**:          [http://github.com/michaeledgar/laser](http://github.com/michaeledgar/laser)   
**Author**:       Michael Edgar    
**Copyright**:    2011  
**License**:      Custom, Academic-use only license. See {file:LICENSE}  
**Latest Version**: 0.1.0    
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
      # x == 5 here, amirite?
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
has a variety of accessor methods created on it that contain the results of static
analysis.

More to come here.

Installing
----------

To install LASER, use the following command:

    $ gem install laser
    
(Add `sudo` if you're installing under a POSIX system as root)
                                                                              

Usage
-----

There are a couple of ways to use LASER. It has a command-line implementation,
and a Rake task. They will be documented further in the future.

Changelog
---------

- **Jan.26.11**: Not publicizing LASER yet, but I figure I need a first entry in
the changelog.


Copyright
---------

LASER &copy; 2011 by [Michael Edgar](mailto:adgar@carboni.ca). See {file:LICENSE}
for licensing details.