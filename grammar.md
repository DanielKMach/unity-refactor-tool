# Grammar

## Syntatic Rules

```java
program -> statement [ ";" statement ]* ";"?
statement -> show | rename | evaluate | update
show -> "SHOW" [ "refs" | [ "direct" | "indirect" ] "uses" ] of? in? where?
rename -> "RENAME" attribure "FOR" attribute of? in? where?
evaluate -> "EVALUATE" expr of? in? where?
update -> "UPDATE" [ "ADD" | "REMOVE" ] asset in? where?
of -> "OF" asset [ "," asset ]*
asset -> identifier | string | "GUID" guid
in -> "IN" identifier | string
where -> "WHERE" expr
expr -> assignment | value | func | op | binary_op | ternary_op
value -> attribute | number | string
assignment -> attribute "=" expr
func -> identifier "(" expr [ "," expr ]* ")"
op -> [ "+" expr | "-" expr | "NOT" expr ]
binary_op -> [ expr "OR" expr | expr "AND" expr | expr "==" expr | expr "!=" expr | expr ">" expr | expr ">=" expr | expr "<" expr | expr "<=" expr | expr "+" expr | expr "-" expr | expr "*" expr | expr "/" expr ]
ternary_op -> expr "?" expr ":" expr
attribute -> identifier | string [ "." identifier | string ]*
```

## Lexical Rules

```java
string -> "\"" .* "\""
guid -> hex{32}
number -> digit* [ "." digit+ ]?
identifier -> letter | "_" [ letter | digit | "_" ]*
hex -> "0" | "1" | "2" | ... | "e" | "f"
letter -> "a" | "b" | "c" | ... | "z"
digit -> "0" | "1" | "2" | ... | "9"
```