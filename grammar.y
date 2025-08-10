program <- statement ( ';' statement )* ';'?
statement <- show / rename / evaluate / update

# === statements ===
show <- 'SHOW' ( 'refs' / ( 'direct' / 'indirect' )? 'uses' ) of in? where?
rename <- 'RENAME' attribure 'FOR' attribute of in? where?
evaluate <- 'EVALUATE' expr of in? where?
update <- 'UPDATE' ( 'ADD' / 'REMOVE' ) asset in? where?

# === clauses ===
of <- 'OF' asset ( ',' asset )*
asset <- literal / string / 'GUID' guid
in <- 'IN' literal / string
where <- 'WHERE' expr

# === expressions ===
expr <- assignment
assignment <- access '=' assignment / or
or <- and ( 'OR' and )*
and <- equality ( 'AND' equality )*
equality <- comparison ( ( '==' / '!=' ) comparison )*
comparison <- term ( ( '>=' / '>' / '<=' / '<' ) term )*
term <- factor ( ( '*' / '/' ) factor )*
factor <- unary ( ( '+' / '-' ) unary )*
unary <- ( ( '-' / 'NOT' ) unary ) / access
access <- value ( '.' value )*
value <- string / number / literal / '(' expr ')'

# === words ===
string <- '"' [^"]* '"'
guid <- hex{32}
number <- digit* ( '.' digit+ )?
literal <- ( alpha / '_' ) ( alphanum / '_' )*

# === single characters ===
hex <- [0-9a-fA-F]
alphanum <- alpha / num
alpha <- [a-zA-Z]
digit <- [0-9]