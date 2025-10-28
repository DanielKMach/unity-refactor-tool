from pygments.lexer import RegexLexer, words
from pygments.token import *

__all__ = ['USRLLexer']

KEYWORDS = {
    'SHOW', 'RENAME', 'EVAL', 'OF', 'IN', 'WHERE', 'HAVING', 'ON', 'FOR', 'GUID',
    'OR', 'AND', 'SELF', 'PARENT', 'ANYCHILD', 'REFS', 'DIRECT', 'INDIRECT', 'USES'
}
OPERATORS = {
    '=', '==', '!=', '>=', '<=', '>', '<', '+=', '-=', '*=', '/=', ':=', '?', ':',
    '++', '--', '+', '-', '*', '/', '??', '!'
}
PUNCTUATION = {
    '.', ',', ';', '(', ')', '[', ']', '{', '}'
}

class USRLLexer(RegexLexer):
    name = 'USRL'
    aliases = ['usrl']
    filenames = ['*.usrl']
    mimetypes = ['text/x-usrl']

    tokens = {
        'root': [
            (r'\s+', Whitespace),
            (words(KEYWORDS, r'\b', r'\b'), Keyword),
            (r'[a-zA-Z_][a-zA-Z0-9_]*', Name),
            (r'\$[a-zA-Z_][a-zA-Z0-9_]*', Name.Variable),
            (r'"[^"]*"', String),
            (r"'[^']*'", String),
            (r'\b\d+(\.\d+)?\b', Number),
            (words(OPERATORS), Operator),
            (words(PUNCTUATION), Punctuation),
            (r'#.*$', Comment.Single),
        ]
    }
