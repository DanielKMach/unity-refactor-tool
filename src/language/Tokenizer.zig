const std = @import("std");
const core = @import("root");
const language = core.language;
const results = core.results;
const log = std.log.scoped(.usql_tokenizer);

const This = @This();
const Token = language.Token;

/// Tokenizes the given expression into a slice of tokens.
///
/// The slice is owned by the caller.
pub fn tokenize(expression: []const u8, allocator: std.mem.Allocator) !results.ParseResult([]Token) {
    core.profiling.begin(tokenize);
    defer core.profiling.stop();

    var list = std.ArrayList(Token).init(allocator);
    defer list.deinit();

    var i: usize = 0;
    while (i < expression.len) : (i += 1) {
        if (language.isWhitespace(expression[i])) { // Ignore whitespace
            continue;
        } else if (language.isAlphabetic(expression[i])) { // identifiers and keywords
            const si = i;
            while (i + 1 < expression.len and language.isAlphanumeric(expression[i + 1])) : (i += 1) {}
            const word = expression[si .. i + 1];
            for (Token.keyword_list) |kw| {
                if (std.ascii.eqlIgnoreCase(word, kw[0])) {
                    try list.append(Token.new(kw[1], word));
                    break;
                }
            } else {
                try list.append(Token.new(.{ .literal = word }, word));
            }
        } else if (expression[i] == '\'' or expression[i] == '"') { // strings
            const si = i;
            i += 1;
            while (expression[i] != expression[si]) : (i += 1) {
                if (i >= expression.len - 1) {
                    return .ERR(.{ .never_closed_string = .{ .index = si } });
                }
            }
            try list.append(Token.new(.{ .string = expression[si + 1 .. i] }, expression[si .. i + 1]));
        } else if (language.isDigit(expression[i]) or (expression[i] == '.' and i + 1 < expression.len and language.isDigit(expression[i + 1]))) { // numbers
            const si = i;
            var has_dot = false;
            if (expression[i] == '.') has_dot = true;
            while (i < expression.len and language.isDigit(expression[i]) or !has_dot and i + 1 < expression.len and expression[i] == '.' and language.isDigit(expression[i + 1])) : (i += 1) {
                if (expression[i] == '.') has_dot = true;
            }
            const number_literal = expression[si..i];
            const number = std.fmt.parseFloat(f32, number_literal) catch {
                return .ERR(.{ .invalid_number = .{ .slice = number_literal } });
            };
            try list.append(Token.new(.{ .number = number }, number_literal));
        } else { // operators
            var best_match: ?@typeInfo(@TypeOf(Token.operator_list)).pointer.child = null;
            for (Token.operator_list) |op| {
                const sign = op[0];
                if (best_match == null or sign.len > best_match.?[0].len and std.mem.eql(u8, expression[i .. i + sign.len], sign)) {
                    best_match = op;
                }
            }
            if (best_match) |operator| {
                try list.append(Token.new(operator[1], expression[i .. i + operator[0].len]));
            } else {
                return .ERR(.{ .unexpected_character = .{ .character = &expression[i] } });
            }
        }
    }

    for (list.items) |tkn| {
        log.info("Token({s}, <{s}>)", .{ @tagName(tkn.value), tkn.lexeme });
    }

    return .OK(try list.toOwnedSlice());
}

/// A token
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
    pub fn split(tokens: []const Token, delimiter: Token.Type, allocator: std.mem.Allocator) std.mem.Allocator.Error![]TokenIterator {
        var list = std.ArrayList(TokenIterator).init(allocator);
        defer list.deinit();
        var start: usize = 0;

        for (tokens, 0..) |tkn, i| {
            if (tkn.is(delimiter)) {
                try list.append(.init(tokens[start..i]));
                start = i + 1;
                continue;
            }
        }
        try list.append(.init(tokens[start..]));

        return list.toOwnedSlice();
    }
};
