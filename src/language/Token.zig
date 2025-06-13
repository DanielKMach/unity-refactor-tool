const std = @import("std");

const Token = @This();

pub const keyword_list: []const struct { []const u8, Value } = &.{
    .{ "SHOW", .SHOW },
    .{ "RENAME", .RENAME },
    .{ "EVAL", .EVALUATE },
    .{ "UPDATE", .UPDATE },
    .{ "OF", .OF },
    .{ "IN", .IN },
    .{ "WHERE", .WHERE },
    .{ "AND", .AND },
    .{ "OR", .OR },
    .{ "NOT", .NOT },
    .{ "GUID", .GUID },
    .{ "DIRECT", .DIRECT },
    .{ "INDIRECT", .INDIRECT },
    .{ "REFS", .REFERENCES },
    .{ "USES", .USES },
    .{ "FOR", .FOR },
};

pub const operator_list: []const struct { []const u8, Value } = &.{
    .{ ".", .dot },
    .{ ",", .comma },
    .{ ";", .eos },
    .{ "+", .plus },
    .{ "-", .minus },
    .{ "*", .star },
    .{ "/", .slash },
};

/// The type of the token.
value: Value,

/// The lexeme of the token, which is the actual text that was matched.
lexeme: []const u8,

/// Creates a new token with the given type and value.
pub fn new(t: Value, lexeme: []const u8) Token {
    return Token{ .value = t, .lexeme = lexeme };
}

/// Checks if the token is of the given type.
pub fn is(self: Token, t: Type) bool {
    return self.value == t;
}

pub const Type = @typeInfo(Value).@"union".tag_type orelse unreachable;

/// The type of tokens that can be recognized by the tokenizer.
pub const Value = union(enum) {
    // Keywords for statements
    SHOW,
    RENAME,
    EVALUATE,
    UPDATE,

    // Keywords for clauses
    OF,
    IN,
    WHERE,

    // Keyword operators
    AND,
    OR,
    NOT,

    // Specialized keywords
    GUID,
    DIRECT,
    INDIRECT,
    REFERENCES,
    USES,
    FOR,

    // Operators
    dot, // '.'
    comma, // ','
    eos, // ';'
    plus, // '+'
    minus, // '-'
    star, // '*'
    slash, // '/'

    /// A number literal.
    number: f32,

    /// A string literal.
    string: []const u8,

    /// Any alphanumeric literal, such as identifiers, component names, etc.
    literal: []const u8,
};
