# USRL

A Unity Structured Refactoring Language (USRL) é uma linguagem de consulta capaz de localizar e manipular instâncias de assets encontradas em projetos Unity, de forma fácil e rápida.

```usrl
SHOW REFS OF "Assets/Sprites/Player.png";
SHOW USES OF PlayerController;

RENAME vel FOR velocidade OF PlayerController;

EVAL velocidade, vida OF PlayerController;
EVAL velocidade *= 2 OF PlayerController;
```

Ela surgiu para suprir a falta de ferramentas de refatoração nativas e foi desenvolvida com o objetivo de auxiliar desenvolvedores de jogos a refatorar e aplicar manutenção em seus projetos.

Aprenda mais sobre a linguagem lendo o [manual da USRL](https://danielkmach.github.io/USRL/).

## Instalação

Para instalar a CLI da linguagem, basta baixar o executável na [página de lançamentos](https://github.com/DanielKMach/USRL/releases) e adicioná-lo ao PATH ou executá-lo diretamente da pasta de download.

A CLI está disponível para os sistemas operacionais windows, linux e macOS.

## Contribuindo

Sinta-se livre para abrir um issue ou fazer uma PR.
