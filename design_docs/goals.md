# LASER Goals

At some point, I need to specify what my actual goals are for this project.
Since the overall point is "static analysis," that's going to involve a wide
variety of things, and since I like being anal about style, I want to include
that too. So I figure: break things down into categories, assign them priorities,
check them off when I'm done.

## Annotations
1. Types of methods/variables
2. Purity/Mutation
3. Generated methods
4. Catch-all annotation of method_missing?

## Style
1. √ Assignment in Conditional (P0)
2. √ raise Exception (P0)
3. √ Inline-Comment Spacing (P0)
4. √ Line-length (P0)
5. √ Useless Whitespace (P0)
6. √ Parens in method declarations (P0)
7. √ Useless Double Quotes/%Q (P0)
8. Operator Spacing (P1)
9. Indentation (P2)
10. Require ! for methods that mutate state (P2)
11. Require ? for methods that always return booleans

## General-Use Information
1. Private Method (P0)
2. Raisability (P0)
3. Yielding (P0)
4. Yield-necessity (P1)
5. Yield-count (P1)
6. Method Purity (P1)
7. Mutation Detection (P1)
8. Types of arguments/return types/variables

## Error Detection
1. NoSuchMethod detection
2. Incorrect # of arguments
3. including already-included module
4. extending already-extended module
5. explicit super with wrong number of args
6. √ re-open class as module (and vice-versa)
7. No block provided to method requiring one
8. Shadowing of really important methods (private = :xyz)
9. Type conflicts
10. Constants in for loops (P0)
11. Useless lhs or rhs in mlhs/mrhs

## Optimization
1. Dead Code Detection
2. Useless variable writes/reads detection
3. Constant Folding