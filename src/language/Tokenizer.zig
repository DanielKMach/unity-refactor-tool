const std = @import("std");
const core = @import("root");
const language = core.language;
const results = core.results;
const log = std.log.scoped(.usql_tokenizer);

const This = @This();

/// Tokenizes the given expression into a slice of tokens.
///
/// The slice is owned by the caller.
pub fn tokenize(expression: []const u8, allocator: std.mem.Allocator) !results.ParseResult([]Token) {
    core.profiling.begin(tokenize);
    defer core.profiling.stop();

    var list = std.ArrayList(Token).init(allocator);
    defer list.deinit();

    var si: usize = 0;
    var i: usize = 0;
    while (i < expression.len) : (i += 1) {
        const char = expression[i];
        const peek = if (i < expression.len - 1) expression[i + 1] else 0;
        if (language.isWhitespace(char)) {
            si = i + 1;
            continue;
        }
        if (si == i and language.isOperator(expression[i])) {
            try list.append(Token.new(.operator, expression[si .. i + 1]));
            si = i + 1;
            continue;
        }
        if ((i == expression.len - 1 or language.isWhitespace(peek) or language.isOperator(peek)) and si != i) {
            const word = expression[si .. i + 1];
            const tpe: TokenType = if (language.isKeyword(word)) .keyword else .literal;
            try list.append(Token.new(tpe, word));
            si = i + 1;
            continue;
        }
        if (char == '\'' or char == '"') {
            si = i;
            i += 1;
            while (expression[i] != expression[si]) : (i += 1) {
                if (i >= expression.len - 1) {
                    return .ERR(.{ .never_closed_string = .{ .index = si } });
                }
            }
            try list.append(Token.new(.string, expression[si + 1 .. i]));
            si = i + 1;
            continue;
        }
        if (si == i and char == ';') {
            try list.append(Token.new(.eos, expression[i .. i + 1]));
            si = i + 1;
            continue;
        }
    }

    for (list.items) |tkn| {
        log.info("Token({s}, '{s}')", .{ @tagName(tkn.type), tkn.value });
    }

    return .OK(try list.toOwnedSlice());
}

/// A token
pub const Token = struct {
    /// The type of the token, such as keyword, operator, number, string, etc.
    type: TokenType,

    /// The value of the token, such as the keyword name, operator symbol, number literal, string literal, etc.
    value: []const u8,

    /// Creates a new token with the given type and value.
    pub fn new(typ: TokenType, value: []const u8) Token {
        return Token{ .type = typ, .value = value };
    }

    /// Compares two tokens if they are equal.
    pub fn eql(self: Token, other: Token) bool {
        return self.type == other.type and std.mem.eql(u8, self.value, other.value);
    }

    /// Checks if the token is of the given type and has the given value.
    pub fn is(self: Token, typ: TokenType, value: []const u8) bool {
        return self.type == typ and std.mem.eql(u8, self.value, value);
    }

    /// Checks if the token is of the given type.
    pub fn isType(self: Token, typ: TokenType) bool {
        return self.type == typ;
    }

    /// Generates a hash for the token.
    ///
    /// Useful for comparing tokens using the switch statement and storing them in hash maps or sets.
    pub fn hash(self: Token) u64 {
        const str = std.hash.RapidHash.hash(0, self.value);
        const typ = std.hash.RapidHash.hash(0, &.{@intFromEnum(self.type)});
        return @addWithOverflow(str, typ)[0];
    }
};

/// The type of tokens that can be recognized by the tokenizer.
pub const TokenType = enum {
    /// A keyword, such as `SHOW`, `OF`, `IN`, `GUID`, etc.
    keyword,

    /// An operator, such as `+`, `-`, `*`, `/`, `=`, etc.
    operator,

    /// A number literal.
    number,

    /// A string literal.
    string,

    /// Any alphanumeric literal, such as identifiers, component names, etc.
    literal,

    /// An end-of-statement token, always a semicolon `;`.
    eos,
};

/// A struct that allows iterating over tokens.
pub const TokenIterator = struct {
    /// The slice of tokens to iterate over.
    ///
    /// It is not recommended to modify this slice while the iterator is in use.
    tokens: []const Token,

    /// The current index in the slice.
    index: isize = -1,

    /// Initializes a new TokenIterator with the given slice of tokens.
    ///
    /// The slice is owned by the caller and *should* not be modified while the iterator is in use.
    ///
    /// The next `next()` call will yield the first token.
    pub fn init(tokens: []const Token) TokenIterator {
        return TokenIterator{
            .tokens = tokens,
            .index = -1,
        };
    }

    /// Steps forward to the next token and returns it.
    ///
    /// Returns `null` if there are no more tokens.
    pub fn next(self: *TokenIterator) ?Token {
        if (self.index + 1 >= self.tokens.len) {
            return null;
        }
        self.index += 1;
        return self.tokens[@intCast(self.index)];
    }

    /// Returns the token `steps` steps ahead of the current index.
    ///
    /// To peek the next token, use `peek(1)`.
    /// If `steps` is negative, it will peek backwards.
    ///
    /// Returns `null` if `steps` is out of bounds.
    pub fn peek(self: TokenIterator, steps: isize) ?Token {
        const i = self.index + steps;
        if (i >= self.tokens.len or i < 0) {
            return null;
        }
        return self.tokens[@intCast(i)];
    }

    /// Returns the amount of tokens left to iterate.
    pub fn len(self: TokenIterator) usize {
        return self.tokens.len - @as(usize, @intCast(self.index + 1));
    }

    /// Resets the iterator to the beginning as if it was just created.
    pub fn reset(self: *TokenIterator) void {
        self.index = -1;
    }

    /// Splits the given slice of tokens by the given delimiter token.
    ///
    /// Useful for separating statements or expressions in a script.
    ///
    /// The returned slice is owned by the caller.
    pub fn split(tokens: []const Token, delimiter: Token, allocator: std.mem.Allocator) std.mem.Allocator.Error![]TokenIterator {
        var list = std.ArrayList(TokenIterator).init(allocator);
        defer list.deinit();
        var start: usize = 0;

        for (tokens, 0..) |tkn, i| {
            if (tkn.eql(delimiter)) {
                try list.append(.init(tokens[start..i]));
                start = i + 1;
                continue;
            }
        }
        try list.append(.init(tokens[start..]));

        return list.toOwnedSlice();
    }
};
