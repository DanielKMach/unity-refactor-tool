## Introdução

A Unity Structured Refactoring Language (USRL) é uma linguagem de consulta capaz de localizar e manipular instâncias de assets encontradas em projetos Unity de forma fácil, rápida e segura.

Ela surgiu para suprir a falta de ferramentas de refatoração nativas e foi desenvolvida com o objetivo de auxiliar desenvolvedores a refatorar e realizar manutenção em seus projetos.

```usrl
SHOW REFS OF "Assets/Sprites/Player.png";
SHOW USES OF PlayerController;

RENAME vel FOR velocidade OF PlayerController;

EVAL velocidade, vida OF PlayerController;
EVAL velocidade *= 2 OF PlayerController;
```

### Principais recursos

- Localizar referências de assets especificados de forma recursiva, podendo especificar expressões como condições para filtrar os resultados.
- Renomear campos de componentes mantendo seus valores após a operação.
- Mostrar e atualizar propriedades com base em valores calculados a partir de expressões lógicas e aritméticas, permitindo a especificação de condições para limitar o escopo das mudanças.

### Avisos e recomendações

A USRL é um projeto atualmente desenvolvido por apenas uma pessoa, portanto há a possibilidade de que a ferramenta não funcione conforme o esperado em algumas ocasiões. É fortemente recomendado que, ao utilizar a USRL em seus projetos Unity, seja possível reverter qualquer alteração feita pela linguagem caso o resultado da operação não seja o desejado. Caso encontre algum bug, por favor, reporte o erro na [página de issues do repositório da USRL](https://github.com/DanielKMach/USRL/issues).

## Instalação

Para obter o interpretador da linguagem, basta baixar o executável na [página de lançamentos do repositório da USRL](https://github.com/DanielKMach/USRL/releases), disponível para os sistemas operacionais Windows, Linux e macOS. Após isso, execute o arquivo por meio de um terminal para ver uma visão geral de todas as funcionalidades disponíveis no executável.

```bash
$ usrl
Usage:
    usrl help          Print this message
    usrl manual        Open the language manual
    usrl interactive   Start interactive mode
    usrl version       Print version
    usrl <args...>     Execute queries (see list below)

Options:
    --file <files...>  Specify one or more files to execute
    --out <file>       Specify the file to output to
    --check            Validates the code without running
    --                 Executes script through the stdin
    <queries...>       Run the specified queries

Examples:
    usrl "SHOW uses OF Player"
    usrl "RENAME _spd FOR _speed OF Player" "EVAL _speed OF Player"
    usrl --file ./script.usrl ./script2.usrl
    usrl "SHOW uses OF Player" -f ./script.usrl
    usrl "SHOW uses OF Player" --out ./log.txt
    usrl help
    usrl manual
    usrl interactive
```

É recomendado renomear o executável para apenas `usrl` e adicionar o seu caminho ao PATH do seu sistema operacional para facilitar o acesso à linguagem e aos seus recursos.
### Visual Studio Code

A USRL também tem uma [extensão oficial para o Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=danielkmach.usrl) para facilitar o aprendizado da linguagem e agilizar o trabalho de desenvolvedores que desejam utilizar a USRL em seus projetos.

## Interface de Linha de Comando

A interface de linha de comando (CLI) da USRL é o principal meio de interação com o sistema de interpretação da linguagem. Ela permite executar consultas USRL, acessar o manual da linguagem e tem a capacidade de exibir mensagens informativas em caso de erro.

### Realizando consultas

Para realizar uma consulta, basta executar a CLI onde cada argumento é uma consulta a ser executada.

```bash
$ usrl "SHOW USES OF Player"
$ usrl "SHOW USES OF Player" "SHOW USES OF Enemy"
```

Para executar um arquivo como um script USRL, é possível usar a opção `--file` (ou `-f`) em seguida o caminho até o arquivo contendo o código USRL.

```bash
$ usrl --file meu_script.usrl
```

A execução de consultas através de *piping* também é uma possibilidade utilizando a opção `--`.

```bash
$ cat script.usrl | usrl --
```

### Opções adicionais

Por padrão, os resultados das consultas realizadas são exibidos no terminal. Utilizando a opção `--out` (ou `-o`), é possível especificar um arquivo de saída para os resultados das consultas.

```bash
$ usrl "SHOW USES OF Player" --out referencias_player.txt
```

### Modo interativo

A CLI tem um modo REPL (Read, Eval, Print, Loop) chamado de *modo interativo*. Para acessá-lo, basta inserir o comando `usrl interactive` ou um dos seus aliases (`usrl i`, `usrl it`) no terminal de sua preferência.

Neste modo cada consulta inserida é executada imediatamente. Ao terminar o processamento de uma consulta, outra poderá ser inserida, de forma contínua sem interrupções.

Uma transação é realizada a cada consulta inserida. Portanto, se ocorrer algum erro durante sua execução, todas as modificações aplicadas serão desfeitas e uma mensagem de erro aparecerá no terminal. Após isso, outras consultas poderão ser inseridas normalmente.


```bash
$ usrl i
>> SHOW USES OF Player
Assets/Prefabs/Player.prefab
Assets/Scenes/Game.unity
>> SHOW USES OF Enemy
Assets/Prefabs/Enemy1.prefab
Assets/Prefabs/Enemy2.prefab
Assets/Scenes/Game.unity
```

## Statements

Consultas na USRL são realizadas através de statements, que representam comandos executáveis responsáveis por buscar, avaliar ou modificar informações dentro dos arquivos de um projeto Unity. Cada statement possui uma função específica dentro da USRL, alguns têm função apenas informativa, enquanto outros aplicam alterações persistentes aos arquivos do projeto.

Esses comandos são identificados por uma palavra-chave própria e funcionam de maneira declarativa, permitindo que o desenvolvedor especifique o quê deve ser feito (como mostrar referências, renomear um campo ou avaliar uma expressão) e quais arquivos serão afetados pela operação, utilizando cláusulas para delimitar o escopo da ação.

### Statement `SHOW`

O statement `SHOW` é utilizado para encontrar referências de assets através do projeto. Este statement aceita qualquer tipo de asset, desde assets visuais como imagens e meshes até componentes e ScriptableObject complexos.

O statement `SHOW` há dois modos de busca distintos: busca por uso e por referência. O modo de busca por referência busca por qualquer menção do asset especificado através dos arquivos do projeto, incluindo referências por campos ou utilização.

O modo de busca por uso é um pouco diferente. Primeiramente é importante destacar que este modo apenas funciona se os assets especificados são componentes ou prefabs, pois são os únicos que podem haver uma instância dentro de um prefab ou cena. Este modo de busca pesquisa pelas instâncias dos componentes/prefabs especificados, incluindo os prefabs que utilizam os assets especificados, de forma recursiva. Por exemplo, se o asset especificado para a busca for o componente `Player.cs` e um prefab chamado `Player.prefab` utiliza este componente, o prefab será incluído na busca, juntamente com o componente originalmente especificado.

É possível modificar o modo de busca utilizando a palavra-chave `REFS` para modo de busca por referência, ou `USES` para o modo de busca por uso.

```usrl
# busca por referências
SHOW REFS OF "Assets/Textures/Player.png";
SHOW REFS OF "Assets/Sounds/Hit.ogg";

# busca por instâncias
SHOW USES OF PlayerController;
SHOW USES OF ObstacleScript, EnemyController;
```

A recursão do modo de busca por uso pode ser explicitamente determinada utilizando as palavras-chave `DIRECT` ou `INDIRECT`. Sendo `INDIRECT` o modo padrão, que realiza a busca recursivamente.

```usrl
# consulta sem recursão
SHOW DIRECT USES OF PlayerController;

# consulta com recursão
SHOW INDIRECT USES OF PlayerController
```

### Statement `RENAME`

O statement `RENAME` é utilizado para renomear os campos dos componentes especificados. Este statement foi desenvolvido para facilitar a renomeação de campos de componentes, evitando a necessidade de renomear manualmente cada campo de cada componente de cada prefab de cada cena, o que pode ser um processo tedioso e propenso a erros.

Para utilizar o statement `RENAME`, é necessário especificar o nome do campo a ser renomeado, o novo nome do campo e, entre eles, a palavra-chave `FOR`. Também é necessário especificar os componentes alvos, utilizando a cláusula `OF`. Note que este statement somente aceita componentes como alvos da operação.

**ATENÇÃO:** Se utilizado no momento incorreto, o statement `RENAME` pode causar a perda dos valores dos campos renomeados. É recomendado executar este statement **após** a modificação do código-fonte do componente e **antes** de focar na janela do editor. Somente assim é possível garantir que a integridade dos dados seja mantida e que os valores dos campos renomeados não sejam perdidos.

```usrl
# renomeia o campo 'vel' para se chamar 'velocidade'
RENAME vel FOR velocidade OF PlayerController;

# renomeia o campo 'pulo' para se chamar 'forcaPulo'
RENAME pulo FOR forcaPulo OF PlayerController
```

A USRL não consegue detectar se um componente é herdado por ou herda alguma outra classe. Portanto, nos casos em que algum componente deriva de um dos componentes especificados, é necessário incluir todos os componentes filhos para que a operação seja realizada de forma correta.

```usrl
# PlayerController e EnemyController herdam de EntityController
RENAME vel FOR velocidade OF EntityController, PlayerController, EnemyController;
RENAME pulo FOR forcaPulo OF EntityController, PlayerController, EnemyController
```

### Statement `EVAL`

O statement `EVAL` é utilizado para avaliar expressões lógicas e aritméticas com base nas propriedades dos componentes especificados, incluindo a possibilidade de reatribuir os valores calculados aos campos de origem. Assim como o statement `RENAME`, este statement aceita apenas componentes como alvos da operação.

```usrl
# mostra o valor do campo 'velocidade' para cada instância de PlayerController encontrada no projeto
EVAL velocidade OF PlayerController;

# mostra o valor do campo 'velocidade' multiplicado por 3.6 para cada instância de PlayerController encontrada no projeto
EVAL velocidade * 3.6 OF PlayerController;

# atualiza o valor de 'velocidade' para ser metade do que era
EVAL velocidade = velocidade / 2 OF PlayerController;

# é possível realizar mais de uma expressão por statement, utilizando vírgulas
EVAL velocidade, vida, fome OF PlayerController;
```

Assim como mencionado no statement `RENAME`, no caso de herança, é indicado incluir explicitamente todos os componentes derivados na operação.

```usrl
# PlayerController e EnemyController herdam de EntityController
EVAL velocidade OF EntityController, PlayerController, EnemyController
```

### Cláusula `OF`

Cláusulas na USRL são componentes sintáticos que permitem especificar parâmetros adicionais e refinar o escopo das operações realizadas pelos statements. Elas funcionam como modificadores que definem onde e quais assets serão afetados por uma determinada operação.

Com a cláusula `OF`, é possível especificar um ou mais assets como alvo da operação. Esta cláusula pode ser utilizada com qualquer asset do projeto, como imagens, clipes de áudio, componentes, prefabs, etc. Esta cláusula necessita do caminho ao asset relativo ao diretório de trabalho atual. Se o asset alvo for um componente, não há necessidade de especificar o caminho, apenas o nome do componente como um literal é suficiente.

```usrl
OF "Imagens/Logo.png"
OF 'Audio/Musica.mp3'

# os exemplos abaixo são equivalentes
OF PlayerController
OF 'Scripts/PlayerController.cs'
```

Se não for possível obter o nome ou caminho ao asset alvo, é possível utilizar seu GUID como substituto. Para especificar o GUID de um asset, deve-se utilizar a palavra-chave `GUID` seguida do GUID como uma string.

```usrl
OF GUID 'e1f42f24601a32ac81a9776a50927ee6'
OF GUID '9ce307d03d67b8de97dbaa43ce7ec8fe'
```

Se houver a necessidade de especificar mais de um asset como alvo da consulta, é possível utilizar vírgulas para este fim. Esta funcionalidade também possibilita a combinação de todos os três métodos de declaração em uma única cláusula.

```usrl
OF 'Scripts/Player.png', 'Scripts/Enemy.png'
OF PlayerController, EnemyController
OF ObstacleScript, 'Textures/obstacle.png', GUID 'a61cf42ea3094c00a7b56d0d270c6f4a'
```

### Cláusula `IN`

A cláusula `IN` serve para especificar o diretório alvo da operação, relativo ao diretório de trabalho atual. Se o diretório desejado for filho direto do diretório de trabalho atual, é possível especificá-lo como um literal.

```usrl
IN './Scenes/Levels'
IN './Resources/Textures/Player'

# os exemplos abaixo são equivalentes
IN Prefabs
IN 'Prefabs'
IN './Prefabs'
IN 'Prefabs/'
```

### Cláusula `WHERE`

A cláusula `WHERE` é utilizada para filtrar os alvos de uma operação, permitindo que apenas os assets que atendem a uma determinada condição sejam incluídos. Para utilizá-la, basta especificar a expressão desejada após a palavra-chave `WHERE`. Esta clausula somente pode ser utilizada se todos os assets alvos forem componentes.

```usrl
# apenas aqueles nos quais 'velocidade' é maior que 10 serão afetados pela operação
WHERE velocidade > 10 

# apenas aqueles nos quais 'vida' é menor que 100 serão afetados pela operação
WHERE vida < 100

# apenas aqueles nos quais 'vida' e 'velocidade' tem o mesmo valor serão afetados pela operação
WHERE velocidade == vida
```

Esta cláusula não é aceita pelo statement `RENAME` pois é uma operação que deve ser aplicada a todos os arquivos igualmente.

## Expressões

O sistema de expressões da USRL permite cálculos e operações lógicas dentro das consultas com base em propriedades e variáveis dadas pelo contexto da operação. Ele amplia as capacidades da linguagem, possibilitando manipulações diretas de valores numéricos, textuais e de propriedades de componentes.

```usrl
1 + 2 + 3 == 6;
'abc' + "def";
velocidade = 10;
vida *= 3;
$min(1, 2) < 2;
$pi := 3.1415;
```

Expressões se baseiam em dois elementos principais: valores e operadores. Cada operação em uma expressão é realizada por um operador. Os operandos e o resultado de uma operação são chamados de valores. Como cada operador aceita e resulta em valores, é possível "aninhar" operadores para realizar tarefas complexas. Cada tipo de valor tem suas próprias características e operadores compatíveis.

Expressões somente podem ser utilizadas quando permitidas pelo statement, assim como o contexto fornecido. Atualmente somente o statement `EVAL` e a cláusula `WHERE` aceitam expressões em suas operações.

### Valores numéricos

Valores numéricos são os valores mais básicos do sistema de expressões. Estes valores representam números reais de alcance infinito e podem participar de operações matemáticas complexas.

```usrl
1, 6.5, 3.14, 24, 0.333
```

Estes valores são internamente representados pelo padrão IEEE 754 de 32 bits.

### Operadores aritméticos

Os operadores aritméticos são responsáveis por realizar operações aritméticas, como adição, subtração, multiplicação e divisão, representadas pelos caracteres `+`, `-`, `*` e `/`, respectivamente. Estes operadores são binários, portanto, aceitam dois operandos e resultam em um único valor numérico.

```usrl
1 + 2, # = 3
8 * 2, # = 16
10 / 2 - 3 # = 2
```

O operador de negação `-` é utilizado para inverter o sinal de um valor numérico, transformando valores positivos em negativos e vice-versa. Este é um operador unário, o que significa que atua sobre apenas um operando.

```usrl
-5, # = -5
--5, # = 5
-(10 + 3), # = -13
```

### Booleanos

Apesar de a linguagem de serialização utilizada pelos assets suportar valores booleanos, a Unity escolheu representá-los através de valores numéricos, de forma que o valor `1` significa verdadeiro e `0` representa falso. A USRL escolheu seguir este padrão, portanto, não há valores booleanos na linguagem.

Em vez disso, todos os valores são implicitamente considerados verdadeiros ou falsos dependendo do seu estado. Valores numéricos são interpretados como verdadeiros quando seu valor é diferente de `0`, enquanto strings são verdadeiras quando não estão vazias.

| Valor | Verdadeiro quando |
| --- | --- |
| Valores numéricos | Diferente de 0 |
| Valores textuais | Comprimento maior que 0 |
| Listas | Sempre |
| Objetos | Sempre |
| Referências | `fileID` diferente de 0 |
| Funções | Sempre |
| Nulo | Nunca |

### Operadores relacionais

Operadores de comparação são utilizados para comparar a diferença entre dois valores numéricos, havendo quatro disponível na linguagem. O resultado dessas operações é `1`, se a comparação é verdadeira ou `0` se é falso.

```usrl
# Todos são verdadeiros 
10 > 3,
2 < 8,
7 >= 7,
7 <= 7
```

Para comparar a igualdade entre dois valores utiliza-se os operadores de igualdade. Assim como as operações de comparação, essas operações resultam em `1` se verdadeiro ou `0` se falso.

```usrl
# Todos são verdadeiros
'23' == "23",
23 == 23,
42 != 35,
'2' != 2
```

### Valores textuais

Valores textuais, também conhecidos como strings, representam cadeias de caracteres de tamanho variável. Sintaticamente são delimitados por aspas simples ou duplas.

```usrl
"abc", 'abc', 'ola mundo!'
```

### Concatenação

Ao utilizar o sinal `+` entre valores de texto, não será realizada uma operação de adição, mas sim uma operação de concatenação, onde os dois valores são unidos em uma única string.

```usrl
'ola' + 'mundo', # = 'olamundo'
1 + '2', # = '12'
'6' + 9 # = '69'
```

### Operadores lógicos

Os operadores lógicos `AND` e `OR` são utilizados para combinar múltiplas condições. O operador `AND` retorna `1` se ambas as condições forem verdadeiras, enquanto `OR` retorna `1` se pelo menos uma das condições for verdadeira.

```usrl
10 > 5 AND 3 < 7, # se torna 1 AND 1 que resulta em 1 (verdadeiro)
'a' == 'a' AND 0, # se torna 1 AND 0 que resulta em 0 (falso)
5 == 5 OR 10 < 2, # se torna 1 OR 0 que resulta em 1 (verdadeiro)
2 != 2 OR 4 < 4, # se torna 0 OR 0 que resulta em 0 (falso)
```

Já o operador de negação lógica `!` é utilizado para inverter o valor lógico de uma expressão. Se a expressão for verdadeira, o resultado será falso, e vice-versa.

```usrl
!(10 > 5), # equivalente a '10 <= 5'
!(velocidade == 0), # equivalente a 'velocidade != 0'
!vida # verdadeiro (1) se vida for igual a 0, caso contrário falso (0)
```

### Objetos e Referências

Objetos são estrutura contendo propriedades nomeadas. Permite acesso hierárquico via o operador de acesso e pode conter valores de qualquer tipo.

Referências são valores que apontam para instâncias de outros assets. Um exemplo de valor referência é a propriedade `m_GameObject`, disponível em todos os componentes e faz referência ao GameObject que está anexado. Estes valores podem ser acessados da mesma forma que objetos, possibilitando o acesso às propriedades daquela instância que o valor faz referência.

Diferentemente dos valores anteriores, não é possível criar um objeto ou referência a partir de uma expressão, visto que ambos vivem dentro do contexto, mas é possível utilizar a função `$addObj()` para adicionar um novo objeto vazio ao contexto atual.

### Acesso

O operador de acesso `.` é utilizado para acessar propriedades de objetos ou referências. Este operador permite navegar através de estruturas hierárquicas de dados.

```usrl
m_GameObject.m_Name, # obtem o nome do GameObject
tamanho.x, # acessa a componente 'x' de 'tamanho'
stats.vida # acessa a propriedade 'vida' de 'stats'
```

A operação resultará em `NIL` se a propriedade acessada não existir.

### Listas

Representa uma coleção ordenada de valores, indexada numericamente a partir de 0. Assim como objetos e referências, este tipo não pode ser criado, mas pode-se utilizar a função `$addList()` para adicionar uma nova lista vazia ao contexto atual.

### Indexação

O operador de indexação `[ ]` é utilizado para acessar um elemento específico de uma lista ou string através de seu índice numérico. Índices começam em `0`, onde o primeiro elemento está localizado. O segundo elemento está no índice `1`, o terceiro no índice `2` e assim por diante.

```usrl
cores[0], # acessa o primeiro elemento da lista cores
posicoes[2], # acessa o terceiro elemento da lista posicoes
vertices[$i] # acessa o elemento no índice especificado pela variável
```

### Nulo (`NIL`)

Representa a ausência de valor e pode ser referenciado através da palavra-chave `NIL`.

### Operadores condicionais

O operador condicional `? :` permite realizar uma operação condicional, retornando um valor se a condição for verdadeira e outro valor se for falsa.

```usrl
vida > 0 ? 'vivo' : 'morto',
velocidade > 10 ? velocidade : 10
```

O operador de null coalescing `??` é utilizado para fornecer um valor padrão quando uma expressão resulta em `NIL`. Este operador avalia o operando à esquerda e retorna o seu valor se for diferente de `NIL`, caso contrário, retorna o valor do operando à direita.

```usrl
vida ?? 100, # retorna 100 se vida for NIL, caso contrário retorna o valor de vida
nome ?? 'Desconhecido', # retorna 'Desconhecido' se nome for NIL
velocidade ?? 0 # retorna 0 se velocidade for NIL
```

### Variáveis e propriedades

Na USRL, existem dois tipos principais de identificadores que podem ser utilizados em expressões: variáveis e propriedades. Embora ambos possam armazenar valores, eles possuem diferenças fundamentais em sua natureza e ciclo de vida.

Propriedades são campos dos componentes que estão sendo manipulados pela operação. Elas são fornecidas pelo objeto de contexto da operação e representam valores reais armazenados nos arquivos do projeto.

Quando você atribui um valor a uma propriedade, essa alteração é persistida ao final da operação, modificando permanentemente o asset correspondente.

```usrl
velocidade = 10;
vida *= 2;
nome = 'Player'
```

Variáveis são identificadores temporários prefixados com o caractere `$`. Elas existem apenas durante a execução da expressão e são descartadas ao final. Variáveis devem ser utilizadas para armazenar valores temporários durante a execução da expressão.

Por padrão, algumas variáveis vêm com valores predefinidos, como funções incorporadas à linguagem. Tentar reatribuir uma variável predefinida resultará em um erro durante a execução da operação.

```usrl
$kph = velocidade * 3.6;
$resultado = $min(vida, 100);
$pi = 3.1415;
$min = 123 # ERRO!
```

Ao contrário das propriedades, que resultam em `NIL`, um erro de execução ocorrerá se uma variável não inicializada for utilizada. Para inicializar uma nova variável, deve-se utilizar o operador `:=`, com o nome da variável à esquerda do operador e o seu valor inicial à direita.

```usrl
# OK
$r := diametro / 2;
perimetro = $r * 2 * 3.14;
area = $r * $r * 3.14;

# ERRADO
velocidade = $kph;
$kph := velocidade * 3.6;
```

### Atribuição

O operador de atribuição possibilita atribuir um valor a uma propriedade ou variável.

```usrl
$diametro = raio * 2;
```

Este operador contém quatro variações que combinam os operadores aritméticos de adição, subtração, multiplicação e divisão ao operador de atribuição, de modo que atualize a propriedade ou variável com base no resultado do cálculo aritmético do operador equivalente.

```usrl
$i += 1; # equivalente a $i = $i + 1
velocidade *= 3.6; # equivalente a velocidade = velocidade * 3.6
vida -= 10; # equivalente a vida = vida - 10
pulo /= 2; # equivalente a pulo = pulo / 2
```

O operador de inicialização é encarregado de inicializar uma variável dado um valor padrão. Este operador sempre deve ser utilizado antes de utilizar ou atribuir a variável.

```usrl
$i := NIL; # inicializando a variável $i
$i = 10; # substituindo seu valor inicial
$i + 2; # utilizando a variável com valor definido
```

### Funções

Funções são valores executáveis que realizam uma tarefa ou calculam um valor. Cada função aceita um número específico de argumentos e devem sempre retornar um valor. Para chamar uma função deve-se utilizar um par de parênteses como sufixo do valor, podendo especificar argumentos dentro dos parênteses, separados por vírgula.

```usrl
$min(10, 5) == 5,
$floor(10.5) == 10,
$len('ola mundo') == 8,
$idx('b', 'abc') == 1,
$ctx().vida == vida
```

A USRL vêm com um conjunto de funções padrão de uso geral para calcular e manipular valores. Tentar atribuir uma variável que contém uma dessas funções resultará em um erro.

#### `$min(x, y)`

Aceita dois argumentos numéricos e retorna o de menor valor. Equivalente a `$x < $y ? $x : $y`.

#### `$max(x, y)`

Aceita dois argumentos numéricos e retorna o de maior valor. Equivalente a `$x > $y ? $x : $y`.

#### `$floor(x)`

Remove a parte fracionária do argumento numérico, arredondando para baixo.

#### `$ceil(x)`

Remove a parte fracionária do argumento numérico, arredondando para cima.

#### `$trunc(x)`

Remove a parte fracionária do argumento numérico, arredondando em direção ao zero.

#### `$round(x)`

Remove a parte fracionária do argumento numérico, arredondando para o valor inteiro mais próximo.

#### `$sqrt(x)`

Retorna a raiz quadrada do argumento numérico.

#### `$abs(x)`

Retorna o valor absoluto do argumento numérico.

#### `$sin(x)`

Aceita um argumento numérico em radianos e retorna o seu seno.

#### `$cos(x)`

Aceita um argumento numérico em radianos e retorna o seu cosseno.

#### `$prop(str)`

Acessa a propriedade do contexto através de uma string.

```usrl
$prop('velocidade') == velocidade,
$prop('vida') == vida
```

#### `$len(lista_str_obj)`

Aceita um argumento de texto, lista ou objeto e retorna seu comprimento.

```usrl
$len('abc'), # retorna o número de caracteres no texto
$len(lista), # retorna o número de elementos na lista
$len(objeto) # retorna o número de pares contidos no objeto
```

#### `$idx(elem, lista_str)`

Retorna o primeiro índice do primeiro argumento dentro do segundo argumento. `NIL`
se não encontrado.

```usrl
$idx('a', 'abcabc') == 0,
$idx('b', 'abcabc') == 1,
$idx('c', 'abcabc') == 2,
$idx('d', 'abcabc') == NIL
```

#### `$lastIdx(elem, lista_str)`

Retorna o último índice do primeiro argumento dentro do segundo argumento. `NIL`
se não encontrado.

```usrl
$lastIdx('a', 'abcabc') == 3,
$lastIdx('b', 'abcabc') == 4,
$lastIdx('c', 'abcabc') == 5,
$lastIdx('d', 'abcabc') == NIL
```

#### `$addList()`

Adiciona uma lista vazia ao contexto e retorna seu valor.

```usrl
$lista := $addList();
$len($lista) == 0;
```

#### `$addObj()`

Adiciona um objeto vazio ao contexto e retorna seu valor.

```usrl
$objeto := $addObj();
$len($objeto) == 0;
```

#### `$push(elem, lista)`

Adiciona o primeiro argumento ao final do segundo argumento. Sempre retorna `NIL`.

```usrl
$lista := $addList();
$push('a', $lista);
$push('b', $lista);
$push('c', $lista);
$len($lista) == 3
```

#### `$pop(lista)`

Remove e retorna o último elemento do argumento.

```usrl
$lista; # [ 'a', 'b', 'c' ]
$pop($lista) == 'c';
$pop($lista) == 'b';
$pop($lista) == 'a';
$len($lista) == 0
```

#### `$slice(str, indice, tamanho)`

Recorta e retorna o primeiro argumento com base nos argumentos seguintes. O segundo argumento é o índice inicial que pode ser negativo. O terceiro argumento é o comprimento do resultado, podendo ser negativo para capturar a string de trás para frente.

```usrl
$slice('abcdef', 1, 2) == 'bc',
$slice('abcdef', 1, -2) == 'ab',
$slice('abcdef', -1, 1) == 'f',
$slice('abcdef', -2, 2) == 'ef',
$slice('abcdef', 3, 999) == 'def',
$slice('abcdef', 3, -999) == 'abcd',
```

#### `$str(x)`

Converte o valor dado em uma string.

#### `$num(x)`

Converte o valor dado em um valor numérico. Somente aceita argumentos textuais ou numéricos.

#### `$ctx()`

Retorna o contexto como um valor, podendo obter suas propriedades através do operador de acesso.

```usrl
$ctx().velocidade == velocidade,
$ctx().vida == vida
```

#### `$fileId(ref)`

Retorna o FileID do valor referência dado, como um valor numérico.

#### `$guid(ref)` 

Retorna o GUID do valor referência dado, como uma string ou nulo, se for uma referência local.

#### `$guidOf(caminho)`

Busca e retorna o GUID do asset no caminho especificado, relativo à raiz do projeto.

```usrl
$guidOf("./Assets/Prefabs/Player.prefab") == "fc0744781169bd7458a2fa1beba80527"
```

#### `$assert(condicao)`

Garante às expressões seguintes que a condição especificada é verdadeira.
Caso contrário, para a execução da consulta e mostra um erro.

```usrl
$assert(rb);
$assert(!rb.m_IsKinematic);
```

### Blocos

Blocos de expressão são a maneira de realizar múltiplas expressões sequencialmente. Um bloco pode conter zero ou mais expressões, separadas por ponto e vírgula. Seus limites são definidos por chaves (`{}`), onde para cada chave aberta, sempre deverá haver uma chave correspondente fechando.

Já que um bloco também é uma expressão, ele deve resultar em um valor. Um bloco sempre retornará o valor da última expressão executada dentro dele, a não ser que esteja vazio, resultando em `NIL`.

```usrl
$area := {
	$r := diametro / 2;
	$r * $r * 3.14
}
```

### Tabela de Operadores

| Precedência | Associatividade    | Caractere                    | Descrição                                                         |
| ----------- | ------------------ | ---------------------------- | ----------------------------------------------------------------- |
| 0           | esquerda à direita | `.`<br>`( )`<br>`[ ]`        | Acesso<br> Chamada de função<br> Indexação                        |
| 1           | direita à esquerda | `-`<br>`!`                   | Negação<br> Negação lógica                                        |
| 2           | esquerda à direita | `??`                         | Null Coalescing                                                   |
| 3           | esquerda à direita | `*`<br>`/`                   | Multiplicação<br> Divisão                                         |
| 4           | esquerda à direita | `+`<br>`-`                   | Adição<br> Subtração                                              |
| 5           | esquerda à direita | `>`<br>`>=`<br>`<`<br>`<=`   | Maior que<br> Maior ou igual a<br> Menor que<br> Menor ou igual a |
| 6           | esquerda à direita | `==`<br>`!=`                 | Igualdade<br> Desigualdade                                        |
| 7           | esquerda à direita | `AND`                        | “E” lógico                                                        |
| 8           | esquerda à direita | `OR`                         | “OU” lógico                                                       |
| 9           | esquerda à direita | `? :`                        | Condicional                                                       |
| 10          | direita à esquerda | `=` `+=` `-=` `*=` `/=` `:=` | Atribuição                                                        |

## Casos de Uso

Esta seção do manual apresenta um conjunto de exemplos práticos, contextualizando os problemas encontrados e demonstrando as capacidades da USRL em solucionar os problemas mencionados.

### Mostrando referências de um asset

Vamos supor que temos um sprite `Gradiente.png` que é frequentemente utilizado para simular ambient occlusion, uma técnica de sombreamento para escurecer cantos onde a luz não chegaria.

Conforme o desenvolvimento do projeto, este asset foi utilizado em algumas cenas diferentes, mas recentemente foi implementada uma solução de sombreamento muito superior comparada com o antigo `Gradiente.png`. Portanto, desejamos substituí-lo e removê-lo do projeto.

Agora temos um problema: como vamos saber em quais cenas aquele asset específico foi utilizado? A USRL tem uma solução para isso. Podemos realizar uma consulta `SHOW` para mostrar todas as referências de `Gradiente.png` espalhadas pelo projeto.

```usrl
SHOW refs OF 'Sprites/Gradiente.png'
```

O resultado será uma lista de cenas que utilizam o asset especificado.

### Exibindo utilizações de componentes

Digamos que temos um componente `Elevador` que é responsável por controlar a movimentação dos elevadores no jogo. Este componente é muito importante para o jogo, pois, sem ele, o jogador ficaria preso nos níveis que dependem do elevador para progredir.

Ao realizar uma mudança neste script, seja introduzir um novo recurso ou até corrigir um bug, sempre há a chance de alterar o comportamento esperado de forma negativa. Portanto, se pudéssemos saber quais cenas utilizam o componente `Elevador`, poderíamos verificar se algum efeito colateral foi introduzido pelas mudanças.

Podemos utilizar o statement `SHOW` para realizar uma varredura pelas cenas do projeto em busca das utilizações do componente.

```usrl
SHOW uses OF Elevador
```

Ao realizar esta consulta, será exibida uma lista de cenas que utilizam o nosso componente `Elevador`.

### Renomeando propriedades

Digamos que temos um componente `Inimigo`, que contém propriedades como velocidade, vida máxima e força. Infelizmente o programador que desenvolveu o componente não sabia nomear variáveis. O resultado foi que a propriedade velocidade se chama `vel`, vida máxima se chama `hp` e força se chama `dano`.

```csharp
public class Inimigo : MonoBehaviour
{
	[SerializeField] float vel;
	[SerializeField] int hp;
	[SerializeField] int dano;
}
```

O problema surge quando percebemos que este componente já foi utilizado vezes demais através do projeto para apenas renomearmos as propriedades, pois ao fazer isso, todos os valores serializados serão perdidos.

A solução para isso é, logo após atualizar o código fonte do componente, realizar uma consulta `RENAME` para garantir que os dados das propriedades sejam mantidos.

```usrl
RENAME vel FOR velocidade OF Inimigo;
RENAME hp FOR vidaMaxima OF Inimigo;
RENAME dano FOR forca OF Inimigo
```

Esta consulta renomeia todas as três propriedades do componente `Inimigo` para cada instância encontrada no projeto.

### Convertendo booleanos em enum

Vamos supor que temos um componente `Moveset` que controla as habilidades de movimentação das entidades do jogo. Para cada habilidade, há um campo booleano que dita se a instância do componente tem aquela habilidade. Conforme o desenvolvimento do projeto, o número de habilidades foi de dois (pular e correr) para cinco (pular, correr, escalar, rolar e nadar). Isso significa que, onde antes tínhamos dois campos, agora temos cinco.

```csharp
public class Moveset : MonoBehaviour
{
	[SerializeField] bool podePular;
	[SerializeField] bool podeCorrer;
	[SerializeField] bool podeEscalar;
	[SerializeField] bool podeRolar;
	[SerializeField] bool podeNadar;
	
	/* ... */
}
```

Para evitar a necessidade de criar um novo campo booleano a cada nova habilidade que implementamos no jogo, podemos atualizar esse sistema para utilizar um enum com flags. Um enum com flags é basicamente um número inteiro onde podemos aproveitar seus bits para armazenar valores binários em uma única variável. Além disso, facilita a adição de novas opções, pois podemos simplesmente adicionar uma nova flag ao enum existente.

```csharp
[System.Flags]
public enum Habilidades
{
	Nenhuma = 0,
	Pular = 1,
	Correr = 2,
	Escalar = 4,
	Rolar = 8,
	Nadar = 16
}
```

Para isso, precisaremos adicionar um novo campo `habilidades`, do tipo `Habilidades`, ao nosso componente `Moveset`. Como podemos ver no editor, o novo campo aparece como esperado no inspetor, mas há uma questão: o seu valor não corresponde aos valores dos campos booleanos. Isso significa que precisaremos atualizar todas as instâncias do componente `Moveset` espalhadas pelo projeto.

Podemos utilizar o statement `EVAL` para efetuar esta atualização de forma automática para cada instância do nosso componente no projeto. Como cada campo booleano é serializado como um número de 0 a 1, podemos utilizar operadores aritméticos para concluir essa tarefa.

```usrl
EVAL habilidades =
	podePular +
	podeCorrer * 2 +
	podeEscalar * 4 +
	podeRolar * 8 +
	podeNadar * 16
OF Moveset
```

Esta consulta computa e atribui o valor esperado ao campo `habilidades` com base nos campos booleanos, de forma automática.

### Transformando referência em array de referências

Vamos supor que temos um componente `SoundboardPlayer` e este componente contém um campo `soundboard` que é do tipo `Soundboard`. O objetivo deste componente é reproduzir o som requisitado através do método `Play`. O campo `soundboard` é um ScriptableObject que contém a lista de clipes necessários para o funcionamento do componente.

```csharp
public class SoundboardPlayer : MonoBehaviour
{
	[SerializeField] Soundboard soundboard;
	
	public void Play(string nomeSom)
	{
		var source = GetComponent<AudioSource>();
		source.clip = soundboard.GetSound(nomeSom);
		source.Play();
	}
}
```

Mas agora temos um problema: atualmente, não é possível reproduzir dois clipes de áudio de dois soundboards diferentes a partir do mesmo `SoundboardPlayer`, já que o componente faz referência a somente um `Soundboard`.

Para resolver este problema, precisamos substituir o campo `soundboard` por um campo novo, do tipo `Soundboard[]`. Chamaremos este novo campo de `soundboardList`. Ao realizar esta mudança, podemos notar que o novo campo aparece no inspetor, como desejado, mas está vazio. Isso significa que precisaremos atribuir o valor do antigo campo `soundboard` como um novo elemento da lista. Precisaremos fazer isso para cada instância do componente `SoundboardPlayer` no projeto, o que pode ser demorado e problemático, dependendo de quantas vezes o componente foi utilizado.

A USRL foi projetada para resolver estes problemas. Podemos utilizar o statement `EVAL` para realizar esta atualização de forma automática.

```usrl
EVAL {
	soundboardList = $addList();
	$push(soundboard, soundboardList);
} OF SoundboardPlayer
```

Esta consulta USRL atribuirá uma nova lista ao campo `soundboardList` e adicionará o valor do antigo campo `soundboard` como um elemento dentro da lista. Esta operação será realizada para cada instância do componente no projeto.

## Apêndices

### Gramática

```
program <- statement ( ';' statement )* ';'?
statement <- show / rename / evaluate

show <- 'SHOW' search of in? where?
rename <- 'RENAME' field 'FOR' ( literal / string ) of in?
evaluate <- 'EVAL' expr ( ',' expr )* of in? where?

of <- 'OF' asset ( ',' asset )*
in <- 'IN' literal / string
where <- 'WHERE' expr

asset <- literal / string / 'GUID' guid
guid <- hex{32}
field <- literal ( '.' literal )*
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
access <- ( literal / variable ) ( '.' literal / '[' expr ']' / '(' ( expr ( ',' expr )* ','? )? ')' )* / value
value <- string / number / '(' expr ')' / '{' ( expr ( ';' expr )* ';'? )? '}'

string <- '"' [^"]* '"'
number <- digit+ ( '.' digit+ )?
literal <- ( alpha / '_' ) ( alpha / digit / '_' )*
variable <- '$' ( alpha / digit / '_' )+

hex <- [0-9a-fA-F]
alpha <- [a-zA-Z]
digit <- [0-9]
```