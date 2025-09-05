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
    .{ "%", .percentage },
    .{ "=", .equal },
    .{ ">", .greater },
    .{ "<", .less },
    .{ "(", .left_paren },
    .{ ")", .right_paren },
    .{ ">=", .greater_equal },
    .{ "<=", .less_equal },
    .{ "!=", .bang_equal },
    .{ "==", .equal_equal },
    .{ "??", .question_question },
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

/// Duplicates the token, the caller owns the returned token.
///
/// Safe to call but unnecessary if token is not a string or literal
pub fn dupe(self: Token, allocator: std.mem.Allocator) std.mem.Allocator.Error!Token {
    const new_value: Value = switch (self.value) {
        .string => |s| .{ .string = try allocator.dupe(u8, s) },
        .literal => |l| .{ .literal = try allocator.dupe(u8, l) },
        else => self.value,
    };
    return Token{
        .value = new_value,
        .loc = self.loc,
    };
}

/// Free token if duped.
///
/// Unnecessary to call if token is not a string or literal.
pub fn cleanup(self: Token, allocator: std.mem.Allocator) void {
    switch (self.value) {
        .string => |s| allocator.free(s),
        .literal => |l| allocator.free(l),
        else => {},
    }
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
    percentage, // '%'
    equal, // '='
    greater, // '>'
    greater_equal, // '>='
    less, // '<'
    less_equal, // '<='
    bang_equal, // '!='
    equal_equal, // '=='
    question_question, // '??'
    left_paren, // '('
    right_paren, // ')'

    /// A number literal.
    number,

    /// A string literal.
    string,

    /// Any alphanumeric literal, such as identifiers, component names, etc.
    literal,

    pub fn format(self: Type, writer: *std.Io.Writer) std.Io.Writer.Error!void {
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
    percentage,
    equal,
    greater,
    greater_equal,
    less,
    less_equal,
    bang_equal,
    equal_equal,
    question_question,
    left_paren,
    right_paren,
    number: f32,
    string: []const u8,
    literal: []const u8,

    pub fn format(self: Value, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        switch (self) {
            .number => |n| try writer.print("number '{d}'", .{n}),
            .string => |s| try writer.print("string '{s}'", .{s}),
            .literal => |l| try writer.print("literal '{s}'", .{l}),
            else => try writer.print("{f}", .{@as(Type, self)}),
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

    pub fn merge(locations: []const Location) Location {
        std.debug.assert(locations.len > 0);
        var min = locations[0].index;
        var max = locations[0].index + locations[0].len;
        for (locations[1..]) |loc| {
            min = @min(min, loc.index);
            max = @max(max, loc.index + loc.len);
        }
        return Location{ .index = min, .len = max - min };
    }
};
