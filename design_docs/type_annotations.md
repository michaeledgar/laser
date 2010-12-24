# The Annotation Syntax

I'll describe this first as a grammar, and then as a list of examples. The value of
each node in the parse tree is a Type. A Type, in my type system, is a set of values
that satisfy the set of constraints placed upon it. Many of these constraints are related
to the Ruby class hierarchy, but not all are. So typically, a nonterminal in this grammar
will represent the creation of a new constraint on the resulting type. Since I do not know
all possible values yet, I will have to represent this type not as the actual set of values,
but as the set of constraints themselves. I will attempt to describe the constraints in english
as comments when they are not typical constraints.

I'll be using a pseudo-flex/bison syntax.

    Tokens:
    /((::)?[A-Z][A-Za-z_]*)+/ -> CONSTANT
    /::/ -> GLOBAL_SCOPE
    /[_a-z][A-Za-z0-9_]*/ -> LOCAL_VAR_ID
    /[_a-z][A-Za-z0-9_]*[?!]?/ -> METHOD_NAME

    Productions:
    top : "Top" { return [] } ; # empty set
    self : "self" { return [SelfTypeConstraint.new] } ;
    unknown : "_" { return [UnknownTypeConstraint.new] }
            | "_" : type_expression { [UnknownTypeConstraint.new(type_expression)] }
            ;

    possibly_mutable_class_constraint : class_constraint '!' {
                                          return (class_constraint << CustomAnnotationConstraint.new(:mutable, true)) }
                                      | class_constraint
                                      ;

    class_constraint : CONSTANT {
                          return [ClassConstraint.new(LookupConstant(constant.text), :covariant)] }
                     ;

    variance_constraint : class_constraint
                        | class_constraint '-' {
                            class_constraint[0].variance = :contravariant; return class_constraint }
                        | class_constraint '=' {
                            class_constraint[0].variance = :invariant; return class_constraint }
                        ;

    generic_class_constraint : possibly_mutable_class_constraint
                             | possibly_mutable_class_constraint "<" generic_type_list ">" {
                                 class_constraint[0] = GenericClassConstraint.new(
                                     class_constraint[0].specified_class, *generic_type_list) }
                             ;

    # no mutability in these – doesn't make sense... or does it? C++ didn't do it, but could I?
    # it would mean deduplication....
    generic_type_list : generic_class_constraint
                      | generic_type_list "," generic_class_constraint { generic_type_list << generic_class_constraint; }
                      ;

    hash_constraint : class_constraint
                    | class_constraint "=>" class_constraint {
                        return [GenericClassConstraint.new(LookupConstant("Hash"), $1[0].specified_class, $3[0].specified_class)] }
                    ;

    union_constraint : hash_constraint { return UnionConstraint.new(hash_constraint) }
                     | union_constraint "|" hash_constraint {
                         return union_constraint | hash_constraint }  # overloaded operator
                     | union_constraint "U" hash_constraint {
                         return union_constraint | hash_constraint }  # overloaded operator
                     | union_constraint "or" hash_constraint {
                         return union_constraint | hash_constraint }  # overloaded operator
                     ;


    structural_constraint : "#" METHOD_NAME '(' generic_type_list ')' return_type
                          
    return_type : { return [] } # empty
                | parenthesized_type_expr
                | "->" parenthesized_type_expr { return parenthesized_type_expr; }

    parenthesized_type_expr : nonparenthesized_type_expr
                            | "(" nonparenthesized_type_expr ")" { return nonparenthesized_type_expr; }
                            ;
    
    type_expression : parenthesized_type_expr ;