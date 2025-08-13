program <- statement ( ';' statement )* ';'?
statement <- show / rename / evaluate / update / add / remove / replace

# === statements ===
show <- 'SHOW' search of in? where?
rename <- 'RENAME' member 'FOR' ( literal / string ) of in? where?
evaluate <- 'EVAL' expr of in? where?
add <- 'ADD' asset in? where? having
remove <- 'REMOVE' asset in? where? having?
replace <- 'REPLACE' asset 'FOR' asset in? where? having?

# === clauses ===
of <- 'OF' asset ( ',' asset )*
in <- 'IN' literal / string
where <- 'WHERE' expr
having <- 'HAVING' asset literal? ( 'ON' target )?

# === constructs ===
asset <- literal / string / 'GUID' guid
guid <- hex{32}
target <- 'self' / 'parent' / 'anychild'
member <- literal ( '.' literal )*
search <- 'refs' / ( 'direct' / 'indirect' )? 'uses'

# === expressions ===
expr <- assignment
assignment <- access '=' or
or <- and ( 'OR' and )*
and <- equality ( 'AND' equality )*
equality <- comparison ( ( '==' / '!=' ) comparison )*
comparison <- term ( ( '>=' / '>' / '<=' / '<' ) term )*
term <- factor ( ( '+' / '-' ) factor )*
factor <- unary ( ( '*' / '/' ) unary )*
unary <- ( '-' / '!' ) unary / access
access <- value ( '.' value )*
value <- string / number / literal / '(' expr ')'

# === words ===
string <- '"' [^"]* '"'
number <- digit+ ( '.' digit+ )?
literal <- ( alpha / '_' ) ( alpha / digit / '_' )*

# === single characters ===
hex <- [0-9a-fA-F]
alpha <- [a-zA-Z]
digit <- [0-9]