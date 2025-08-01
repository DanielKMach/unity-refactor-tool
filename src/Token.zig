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
    .{ "=", .equal },
    .{ ">", .greater },
    .{ "<", .less },
    .{ "(", .left_paren },
    .{ ")", .right_paren },
    .{ ">=", .greater_equal },
    .{ "<=", .less_equal },
    .{ "!=", .bang_equal },
    .{ "==", .equal_equal },
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

pub const Type = enum {
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
    equal, // '='
    greater, // '>'
    greater_equal, // '>='
    less, // '<'
    less_equal, // '<='
    bang_equal, // '!='
    equal_equal, // '=='
    left_paren, // '('
    right_paren, // ')'

    /// A number literal.
    number,

    /// A string literal.
    string,

    /// Any alphanumeric literal, such as identifiers, component names, etc.
    literal,

    pub fn format(
        self: Type,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        inline for (operator_list) |op| {
            if (self == op[1]) {
                return writer.print("'{s}'", .{op[0]});
            }
        }
        inline for (keyword_list) |kw| {
            if (self == kw[1]) {
                return writer.print("'{s}'", .{kw[0]});
            }
        }
        return writer.print("{s}", .{@tagName(self)});
    }
};

/// The type of tokens that can be recognized by the tokenizer.
pub const Value = union(Type) {
    SHOW,
    RENAME,
    EVAL,
    UPDATE,
    OF,
    IN,
    WHERE,
    AND,
    OR,
    NOT,
    GUID,
    DIRECT,
    INDIRECT,
    REFS,
    USES,
    FOR,
    dot,
    comma,
    eos,
    plus,
    minus,
    star,
    slash,
    equal,
    greater,
    greater_equal,
    less,
    less_equal,
    bang_equal,
    equal_equal,
    left_paren,
    right_paren,
    number: f32,
    string: []const u8,
    literal: []const u8,

    pub fn format(
        self: Value,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) anyerror!void {
        switch (self) {
            .number => |n| try writer.print("number '{d}'", .{n}),
            .string => |s| try writer.print("string '{s}'", .{s}),
            .literal => |l| try writer.print("literal '{s}'", .{l}),
            else => try writer.print("{}", .{@as(Type, self)}),
        }
    }
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
