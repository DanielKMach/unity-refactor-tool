# USRL

<center>Unity Structured Refactoring Language</center>

## Introdução

### Gramática

```
program <- statement ( ';' statement )* ';'?
statement <- show / rename / evaluate

show <- 'SHOW' search of in? where?
rename <- 'RENAME' member 'FOR' ( literal / string ) of in? where?
evaluate <- 'EVAL' expr of in? where?

of <- 'OF' asset ( ',' asset )*
in <- 'IN' literal / string
where <- 'WHERE' expr
having <- 'HAVING' asset variable? ( 'ON' target )?

asset <- literal / string / 'GUID' guid
guid <- hex{32}
target <- 'self' / 'parent' / 'anychild'
member <- literal ( '.' literal )*
search <- 'refs' / ( 'direct' / 'indirect' )? 'uses'

expr <- assignment
assignment <- access ( '=' / '+=' / '-=' / '*=' / '/=' / ':=' ) assignment / ternary
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

string <- '"' [^"]* '"'
number <- digit+ ( '.' digit+ )?
literal <- ( alpha / '_' ) ( alpha / digit / '_' )*
variable <- '$' ( alpha / digit / '_' )+

hex <- [0-9a-fA-F]
alpha <- [a-zA-Z]
digit <- [0-9]
```

## Expressões

### Valores

### Operadores

A seguir está a lista de operadores utilizados pela USRL.

| Precedência | Sequência | Descrição | Associatividade |
| --- | --- | --- | --- |
| <center>0</center> | .<br>( )<br>[ ] | Acesso<br>Chamada de função<br>Indexação | esquerda à direita |
| <center>1</center> | -<br>! | Negação<br>Negação lógica | direita à esquerda |
| <center>2</center> | ?? | Null Coalescing | esquerda à direita |
| <center>3</center> | *<br>/ | Multiplicação<br>Divisão | esquerda à direita |
| <center>4</center> | +<br>- | Adição<br>Subtração | esquerda à direita |
| <center>5</center> | ><br>>=<br><<br><= | Maior que<br>Maior ou igual a<br>Menor que<br>Menor ou igual a | esquerda à direita |
| <center>6</center> | ==<br>!= | Igualdade<br>Desigualdade | esquerda à direita |
| <center>7</center> | AND | “E” lógico | esquerda à direita |
| <center>8</center> | OR | “OU” lógico | esquerda à direita |
| <center>9</center> | ? : | Condicional | esquerda à direita |
| <center>10</center> | = += -= *= /= := | Atribuição | direita à esquerda |

### Funções

## Cláusulas

### Cláusula `OF`

Com a cláusula `OF`, é possível especificar um ou mais *assets* como alvo da consulta. Em muitos *statements*, esta cláusula é obrigatória, apesar de não haver a necessidade de ser a primeira.

A cláusula `OF` pode ser utilizada com qualquer *asset* do projeto, como imagens, clipes de áudio, componente, prefabs, etc. Esta cláusula necessita do caminho ao *asset* relativo ao diretório atual de trabalho. Se o *asset* alvo for um componente, não há necessidade de especificar o caminho, apenas o nome do componente como um literal é o suficiente.

```usrl
OF "Imagens/Logo.png"
OF 'Audio/Musica.mp3'

# Os exemplos abaixo são equivalentes
OF PlayerController
OF 'Scripts/PlayerController.cs'
```

Também é possível utilizar o operador `,` (vírgula) para especificar mais de um *asset*.

```usrl
OF 'Scripts/Player.png', 'Scripts/Enemy.png' 

# Os exemplos abaixo são equivalentes
OF PlayerController, EnemyController
OF PlayerController, 'Scripts/EnemyController.cs' 
OF 'Scripts/PlayerController.cs', 'Scripts/EnemyController.cs'
```

Se houver alguma situação que não seja possível obter o nome ou caminho ao *asset*, é possível utilizar seu GUID como substituto. Para especificar o GUID de um *asset*, deve-se utilizar a palavra-chave `GUID` seguida do GUID como uma string.

```usrl
OF GUID 'e1f42f24601a32ac81a9776a50927ee6'
OF GUID 'e1f42f24601a32ac81a9776a50927ee6', GUID '9ce307d03d67b8de97dbaa43ce7ec8fe'
OF PlayerController, GUID '9ce307d03d67b8de97dbaa43ce7ec8fe'
```

### Cláusula `IN`

A cláusula `IN` serve para especificar o diretório alvo da operação, relativo ao diretório de trabalho atual. Se o diretório especificado for filho direto do diretório de trabalho atual, é possível especificá-lo como um literal.

```usrl
IN './Scenes/Levels'
IN './Resources/Textures/Player'

# Os exemplos abaixo são equivalentes
IN Prefabs
IN 'Prefabs'
IN './Prefabs'
IN 'Prefabs/'
```

### Cláusula `WHERE`

A cláusula `WHERE` é utilizada para filtrar os resultados de uma operação, permitindo que apenas os assets que atendem a uma determinada condição sejam incluídos. Para utilizá-la, basta especificar a expressão desejada após a palavra-chave `WHERE`.

```usrl
WHERE _speed > 10
WHERE _health < 100
WHERE _speed == _health
```

## Statements

### Statement `SHOW`

O statement `SHOW` é utilizado para buscar referências de assets específicos em cenas ou prefabs. Este statement tem dois modos de busca: **referências** e **usos**.

O modo de **busca por referência** é simples: Este modo realiza uma busca por qualquer utilização do asset especificado, incluindo referências através de campos, através de todas as cenas, prefabs e assets do projeto.

O modo de **busca por uso** é um pouco diferente. É importante deixar claro que este modo apenas funciona se o asset especificado for um componente ou prefab. Este modo pesquisa pelas utilizações do componente/prefab especificado, inclusive a utilização dos prefabs que utilizam o asset especificado, de forma recursiva. Por exemplo, se o asset especificado para a busca for o componente `Player.cs` e um prefab chamado `Player.prefab` utilizar este componente, o prefab será incluído na busca, juntamente com o componente originalmente especificado.

É possível modificar o modo de busca utilizando a palavra-chave `REFS` para modo de busca por
referência, ou `USES` para o modo de busca por uso

```usrl
SHOW USES OF PlayerController IN Assets;
SHOW USES OF 'Assets/Prefabs/Player.prefab' IN Assets;
SHOW REFS OF "Assets/Textures/Player.png"
```

A recursão do modo de **busca por uso** pode ser explicitamente determinada utilizando as palavras-chave `DIRECT` ou `INDIRECT`. Sendo `INDIRECT` o modo padrão, que realiza a busca recursivamente.

```usrl
SHOW DIRECT USES OF PlayerController;
SHOW INDIRECT USES OF PlayerController
```

### Statement `RENAME`

O statement `RENAME` é utilizado para renomear os campos dos componentes especificados. Este statement foi criado para facilitar a renomeação de campos de componentes, evitando a necessidade de renomear manualmente cada campo de cada componente de cada prefab de cada cena, o que pode ser um processo tedioso e propenso a erros.

Para utilizar o statement `RENAME`, é necessário especificar o nome do campo a ser renomeado, o novo nome do campo e, entre eles, a palavra-chave `FOR`. Também é necessário especificar o componente alvo, utilizando a cláusula `OF`.

```usrl
RENAME _spd FOR _speed OF PlayerController;
RENAME _life FOR _health OF PlayerController
```

Em caso de classes com hierarquia, é possível especificar mais de um componente, utilizando a cláusula `OF` com mais de um componente, separados por vírgula. O statement `RENAME` irá renomear o campo especificado em todos os componentes especificados.

```usrl
RENAME _spd FOR _speed OF PlayerController, EntityController;
RENAME _life FOR _health OF PlayerController, EntityController
```

**ATENÇÃO:** Se utilizado no momento incorreto, o statement `RENAME` pode causar a perda dos valores dos campos renomeados. Este statement deve ser utilizado **após** o renomeamento dos campos da classe do componente, ou seja, após a modificação do código fonte do componente, e **antes** de focar na janela do editor. Somente assim é possível garantir que a integridade dos dados seja mantida e que os valores dos campos renomeados não sejam perdidos.

### Statement `EVAL`

O statement `EVAL` é utilizado para avaliar expressões matemáticas, lógicas e de comparação com base
nos valores dos campos dos componentes especificados.

```usrl
EVAL _speed OF PlayerController;
EVAL _speed / 3.6 OF PlayerController
```

Este statement também permite a reatribuição de valores aos campos.

```usrl
EVAL _speed /= _speed * 3.6 OF PlayerController;
EVAL _speed = 100 / _health OF PlayerController
```

Este statement pode ser combinado com a cláusula `WHERE` para limitar o escopo das mudanças.

```usrl
EVAL _speed = 10 OF PlayerController WHERE _speed > 10
```

## Interface de Linha de Comando

A interface de linha de comando (CLI) é o sistema que permite a execução de código USRL. Ela serve de janela entre o usuário e o sistema de interpretação e execução da linguagem.

```
$ usrl
Usage:
    usrl help          Print this message
    usrl manual        Open the language manual
    usrl interactive   Start interactive mode
    usrl <args...>     Execute queries (see list below)

Options:
    --file <files...>  Specify one or more files to execute
    --output <file>    Specify the file to output to
    --                 Executes script through the stdin
    <queries...>       Run the specified queries

Examples:
    usrl "SHOW uses OF Player"
    usrl "RENAME _spd FOR _speed OF Player" "EVAL _speed OF Player"
    usrl --file ./script.usrl ./script2.usrl
    usrl "SHOW uses OF Player" -f ./script.usrl
    usrl "SHOW uses OF Player" --output ./log.txt
    usrl help
    usrl manual
    usrl interactive
```

### Executando consultas

### Modo interativo

A CLI tem um modo REPL (Read, Eval, Print, Loop) chamado *modo interativo.* Para acessá-lo o modo interativo, basta inserir o comando `usrl interactive` ou um dos seus aliases (`usrl i`, `usrl int`) no shell de sua preferência.

Neste modo cada consulta inserida é executada imediatamente. Ao terminar o processamento de uma consulta, outra poderá ser inserida, de forma contínua sem interrupções.

Uma transaction é realizada a cada comando inserido, portanto, se ocorrer algum erro durante a execução de uma consulta, todas as modificações realizadas serão desfeitas e poderá inserir outra consulta normalmente.

```
$ usrl i
>> SHOW USES OF Player
Assets/Prefabs/Player.prefab
Assets/Scenes/Game.unity
>> SHOW USES OF Enemy
Assets/Prefabs/Enemy1.prefab
Assets/Prefabs/Enemy2.prefab
Assets/Scenes/Game.unity
```

### Acesso ao manual

A CLI vem com o manual da linguagem inserido dentro de seu binário. Para acessá-lo, basta executar o comando `usrl manual` no seu shell de preferência. Isso irá criar um arquivo novo no diretório de trabalho atual chamado `manual.html`.

## Exemplos

### Verificando referências

### Renomeando propriedades

### Atualizando valores