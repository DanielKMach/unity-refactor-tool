const std = @import("std");

const Token = @This();

pub const keyword_list: []const struct { []const u8, Value } = &.{
    .{ "SHOW", .SHOW },
    .{ "RENAME", .RENAME },
    .{ "EVAL", .EVAL },
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
    .{ "REFS", .REFS },
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
loc: Location,

/// Creates a new token with the given type and value.
pub fn new(value: Value, loc: Location) Token {
    return Token{
        .value = value,
        .loc = loc,
    };
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
    EVAL,
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
    REFS,
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

pub const Location = struct {
    index: usize,
    len: usize,

    pub fn init(index: usize, len: usize) Location {
        return Location{
            .index = index,
            .len = len,
        };
    }

    pub fn fromSlice(string: []const u8, slice: []const u8) Location {
        const zero = @intFromPtr(string.ptr);
        return Location{
            .index = @intFromPtr(slice.ptr) - zero,
            .len = slice.len,
        };
    }

    pub fn lexeme(self: Location, string: []const u8) []const u8 {
        return string[self.index .. self.index + self.len];
    }
};
