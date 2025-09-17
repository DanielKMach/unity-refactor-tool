program <- statement ( ';' statement )* ';'?
statement <- show / rename / evaluate

# === statements ===
show <- 'SHOW' search of in? where?
rename <- 'RENAME' member 'FOR' ( literal / string ) of in? where?
evaluate <- 'EVAL' expr of in? where?

# === clauses ===
of <- 'OF' asset ( ',' asset )*
in <- 'IN' literal / string
where <- 'WHERE' expr
having <- 'HAVING' asset variable? ( 'ON' target )?

# === constructs ===
asset <- literal / string / 'GUID' guid
guid <- hex{32}
target <- 'self' / 'parent' / 'anychild'
member <- literal ( '.' literal )*
search <- 'refs' / ( 'direct' / 'indirect' )? 'uses'

# === expressions ===
expr <- assignment
assignment <- access '=' assignment / ternary
ternary <- or ( '?' or ':' ternary )?
or <- and ( 'OR' and )*
and <- equality ( 'AND' equality )*
equality <- comparison ( ( '==' / '!=' ) comparison )*
comparison <- term ( ( '>=' / '>' / '<=' / '<' ) term )*
term <- factor ( ( '+' / '-' ) factor )*
factor <- coalesce ( ( '*' / '/' ) coalesce )*
coalesce <- unary ( '??' unary )*
unary <- ( '-' / '!' ) unary / access
access <- ( literal / variable ) ( '.' literal / '[' expr ']' / '(' ( expr ( ',' expr )* )? ')' )* / value 
value <- string / number / '(' expr ')'

# === words ===
string <- '"' [^"]* '"'
number <- digit+ ( '.' digit+ )?
literal <- ( alpha / '_' ) ( alpha / digit / '_' )*
variable <- '$' ( alpha / digit / '_' )+

# === single characters ===
hex <- [0-9a-fA-F]
alpha <- [a-zA-Z]
digit <- [0-9]