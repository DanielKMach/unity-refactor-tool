const std = @import("std");
const core = @import("core");

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
    .{ "NIL", .NIL },
};

pub const operator_list: []const struct { []const u8, Value } = &.{
    .{ ".", .dot },
    .{ ",", .comma },
    .{ "+", .plus },
    .{ "-", .minus },
    .{ "*", .star },
    .{ "/", .slash },
    .{ "%", .percentage },
    .{ "=", .equal },
    .{ "+=", .plus_equal },
    .{ "-=", .minus_equal },
    .{ "*=", .star_equal },
    .{ "/=", .slash_equal },
    .{ ":=", .colon_equal },
    .{ ">", .greater },
    .{ "<", .less },
    .{ "(", .left_paren },
    .{ ")", .right_paren },
    .{ ">=", .greater_equal },
    .{ "<=", .less_equal },
    .{ "!=", .bang_equal },
    .{ "==", .equal_equal },
    .{ "??", .question_question },
    .{ "?", .question },
    .{ ":", .colon },
    .{ ";", .semicolon },
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

/// Returns the value of the token if a string or literal.
pub fn asSlice(self: Token) []const u8 {
    switch (self.value) {
        .string => |s| return s,
        .literal => |l| return l,
        else => @panic("Token.asSlice called on non-string/literal token"),
    }
}

/// Duplicates the token, the caller owns the returned token.
///
/// Safe to call but unnecessary if token is not a string or literal
pub fn dupe(self: Token, allocator: std.mem.Allocator) std.mem.Allocator.Error!Token {
    const new_value: Value = switch (self.value) {
        .string => |s| .{ .string = try allocator.dupe(u8, s) },
        .literal => |l| .{ .literal = try allocator.dupe(u8, l) },
        .variable => |v| .{ .variable = try allocator.dupe(u8, v) },
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
        .variable => |v| allocator.free(v),
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
    NIL,

    // Operators
    dot, // '.'
    comma, // ','
    plus, // '+'
    minus, // '-'
    star, // '*'
    slash, // '/'
    percentage, // '%'
    equal, // '='
    plus_equal, // '+='
    minus_equal, // '-='
    star_equal, // '*='
    slash_equal, // '/='
    colon_equal, // ':='
    greater, // '>'
    greater_equal, // '>='
    less, // '<'
    less_equal, // '<='
    bang_equal, // '!='
    equal_equal, // '=='
    question_question, // '??'
    question, // '?'
    colon, // ':'
    semicolon, // ';'
    left_paren, // '('
    right_paren, // ')'

    /// A number literal.
    number,

    /// A string literal.
    string,

    /// Any alphanumeric literal, such as identifiers, component names, etc.
    literal,

    /// Any alphanumeric literal with a leading '$'.
    variable,

    /// End of file, used to indicate the end of input.
    eof,

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
        return writer.print("{t}", .{self});
    }

    pub fn raw(self: Type, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        inline for (operator_list) |op| {
            if (self == op[1]) {
                return writer.print("{s}", .{op[0]});
            }
        }
        inline for (keyword_list) |kw| {
            if (self == kw[1]) {
                return writer.print("{s}", .{kw[0]});
            }
        }
        return writer.print("{t}", .{self});
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
    NIL,
    dot,
    comma,
    plus,
    minus,
    star,
    slash,
    percentage,
    equal,
    plus_equal,
    minus_equal,
    star_equal,
    slash_equal,
    colon_equal,
    greater,
    greater_equal,
    less,
    less_equal,
    bang_equal,
    equal_equal,
    question_question,
    question,
    colon,
    semicolon,
    left_paren,
    right_paren,
    number: f32,
    string: []const u8,
    literal: []const u8,
    variable: []const u8,
    eof,

    pub fn format(self: Value, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        switch (self) {
            .number => |n| try writer.print("number '{d}'", .{n}),
            .string => |s| try writer.print("string '{s}'", .{s}),
            .literal => |l| try writer.print("literal '{s}'", .{l}),
            .variable => |v| try writer.print("variable '${s}'", .{v}),
            else => try @as(Type, self).format(writer),
        }
    }

    pub fn raw(self: Value, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        switch (self) {
            .number => |n| try writer.print("{d}", .{n}),
            .string => |s| try writer.print("'{s}'", .{s}),
            .literal => |l| try writer.print("`{s}`", .{l}),
            .variable => |v| try writer.print("${s}", .{v}),
            else => try @as(Type, self).raw(writer),
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

/// A token
/// A struct that allows iterating over tokens.
pub const Iterator = struct {
    /// The slice of tokens to iterate over.
    ///
    /// It is not recommended to modify this slice while the iterator is in use.
    tokens: []const Token,

    /// The index of the next token to yield.
    index: usize = 0,

    /// Initializes a new TokenIterator with the given slice of tokens.
    ///
    /// The slice is owned by the caller and *should* not be modified while the iterator is in use.
    ///
    /// The next `next()` call will yield the first token.
    pub fn init(tokens: []const Token) Iterator {
        return Iterator{
            .tokens = tokens,
            .index = 0,
        };
    }

    /// Steps forward to the next token and returns it.
    ///
    /// If out of bounds, returns the last token (usually end-of-statement)
    pub fn next(self: *Iterator) Token {
        if (self.index >= self.tokens.len) {
            return self.tokens[self.tokens.len - 1];
        }
        defer self.index += 1;
        return self.tokens[self.index];
    }

    /// Returns the token `steps` steps ahead of the current index.
    ///
    /// To peek the next token, use `peek(1)`.
    /// To peek the previous token, use `peek(0)`.
    ///
    /// If out of bounds, returns the last token (usually end-of-statement)
    pub fn peek(self: Iterator, steps: usize) Token {
        if (self.index == 0 and steps == 0) @panic("Cannot peek at 0 before the start of the iterator");
        const i: usize = self.index + steps - 1;
        if (i >= self.tokens.len) {
            return self.tokens[self.tokens.len - 1];
        }

        return self.tokens[i];
    }

    /// Checks if the next token matches the expected type.
    /// If so, consumes and returns the token.
    pub fn consume(self: *Iterator, t: Type) ?Token {
        if (self.peek(1).is(t)) {
            return self.next();
        }
        return null;
    }

    /// Checks if the next token matches any of the expected types.
    /// If so, consumes and returns the token
    pub fn consumeAny(self: *Iterator, types: []const Type) ?Token {
        for (types) |t| {
            if (self.consume(t)) |mat| return mat;
        }
        return null;
    }

    /// Consumes and returns the next token if it matches the expected type.
    /// Otherwise, returns a parse error via the given diagnostics.
    pub fn grab(self: *Iterator, expected: Type, diag: *core.ParseDiagnostics) core.ParseDiagnostics.Error!Token {
        if (self.consume(expected)) |t| return t;
        return diag.push(.{ .unexpected_token = .{
            .found = self.peek(1),
            .expected = &.{expected},
        } });
    }

    /// Consumes and returns the next token if it matches any of the expected types.
    /// Otherwise, returns a parse error via the given diagnostics.
    pub fn grabAny(self: *Iterator, expected: []const Type, diag: *core.ParseDiagnostics) core.ParseDiagnostics.Error!Token {
        if (self.consumeAny(expected)) |t| return t;
        return diag.push(.{ .unexpected_token = .{
            .found = self.peek(1),
            .expected = expected,
        } });
    }

    /// Returns whether the next token matches the expected type.
    /// If so, consumes the token.
    pub fn match(self: *Iterator, expected: Type) bool {
        return self.consume(expected) != null;
    }

    /// Returns the amount of tokens left to iterate.
    pub fn remaining(self: Iterator) usize {
        return self.tokens.len - self.index;
    }

    /// Resets the iterator to the beginning as if it was just created.
    pub fn reset(self: *Iterator) void {
        self.index = 0;
    }
};
