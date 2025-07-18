const std = @import("std");
const core = @import("core");
const parsing = core.parsing;
const results = core.results;
const log = std.log.scoped(.usql_tokenizer);

const This = @This();
const Token = core.Token;

const whitespace = " \t\r\n";
const alphabetic = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
const digit = "0123456789";
const alphanumeric = alphabetic ++ digit;

source: []const u8,
index: usize = 0,

pub fn init(source: []const u8) This {
    return This{
        .source = source,
    };
}

fn next(self: *This) ?u8 {
    if (self.index >= self.source.len) {
        return null;
    }
    const c = self.source[self.index];
    self.index += 1;
    return c;
}

fn match(self: *This, chars: []const u8) bool {
    if (self.index >= self.source.len) {
        return false;
    }
    for (chars) |ch| {
        if (self.source[self.index] == ch) {
            self.index += 1;
            return true;
        }
    }
    return false;
}

fn peek(self: This) ?u8 {
    if (self.index >= self.source.len) {
        return null;
    }
    return self.source[self.index];
}

fn at(self: This, index: usize) ?u8 {
    if (index >= self.source.len) {
        return null;
    }
    return self.source[index];
}

fn slice(self: This, start: usize, end_offset: isize) []const u8 {
    const end: usize = @intCast(@as(isize, @intCast(self.index)) + end_offset);
    if (end >= self.source.len) {
        return self.source[start..];
    }
    return self.source[start..end];
}

fn sliceForward(self: This, start_offset: isize, len: usize) []const u8 {
    const start: usize = @intCast(@as(isize, @intCast(self.index)) + start_offset);
    if (start + len >= self.source.len) return self.source[start..];
    return self.source[start .. start + len];
}

pub fn token(self: *This) results.ParseResult(?Token) {
    while (self.match(whitespace ++ "#")) {
        if (self.at(self.index - 1) == '#') {
            while (self.next()) |n| {
                if (n == '\n') break;
            }
        }
    }
    if (self.peek() == null) {
        return .OK(null);
    }

    const start = self.index;
    if (self.match(alphabetic ++ "_")) { // identifiers and keywords
        while (self.match(alphanumeric ++ "_")) {}
        const word = self.slice(start, 0);
        for (Token.keyword_list) |kw| {
            if (std.ascii.eqlIgnoreCase(word, kw[0])) {
                return .OK(.new(kw[1], .fromSlice(self.source, word)));
            }
        } else {
            return .OK(.new(.{ .literal = word }, .fromSlice(self.source, word)));
        }
    } else if (self.match("\"'")) { // strings
        while (self.next()) |c| {
            if (c == self.at(start)) {
                const str = self.slice(start + 1, -1);
                return .OK(.new(.{ .string = str }, .init(start, str.len + 2)));
            }
        } else {
            return .ERR(.{ .never_closed_string = .{ .location = .init(start, 1) } });
        }
    } else if (self.match(digit)) {
        while (self.match(digit ++ ".")) {}
        const number_literal = self.slice(start, 0);
        const number = std.fmt.parseFloat(f32, number_literal) catch {
            return .ERR(.{ .invalid_number = .{ .location = .fromSlice(self.source, number_literal) } });
        };
        return .OK(.new(.{ .number = number }, .fromSlice(self.source, number_literal)));
    } else { // operators
        var best_match: ?@typeInfo(@TypeOf(Token.operator_list)).pointer.child = null;
        for (Token.operator_list) |op| {
            const sign = op[0];
            if ((best_match == null or sign.len >= best_match.?[0].len) and std.mem.eql(u8, self.sliceForward(0, sign.len), sign)) {
                best_match = op;
            }
        }
        if (best_match) |operator| {
            defer self.index += operator[0].len;
            return .OK(.new(operator[1], .init(self.index, operator[0].len)));
        } else {
            return .ERR(.{ .unexpected_character = .{ .location = .init(self.index, 1) } });
        }
    }
}

/// Tokenizes the given expression into a slice of tokens.
///
/// The slice is owned by the caller.
pub fn tokenize(expression: []const u8, allocator: std.mem.Allocator) !results.ParseResult([]Token) {
    core.profiling.begin(tokenize);
    defer core.profiling.stop();

    var list = std.ArrayList(Token).init(allocator);
    defer list.deinit();

    var tokenizer = This.init(expression);
    while (true) {
        switch (tokenizer.token()) {
            .ok => |t| try list.append(t orelse break),
            .err => |err| return .ERR(err),
        }
    }

    if (!list.items[list.items.len - 1].is(.eos)) {
        try list.append(Token.new(.eos, .init(expression.len, 0)));
    }

    for (list.items) |tkn| {
        log.info("Token({s}, <{s}>)", .{ @tagName(tkn.value), tkn.loc.lexeme(expression) });
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

    /// The index of the next token to yield.
    index: usize = 0,

    /// Initializes a new TokenIterator with the given slice of tokens.
    ///
    /// The slice is owned by the caller and *should* not be modified while the iterator is in use.
    ///
    /// The next `next()` call will yield the first token.
    pub fn init(tokens: []const Token) TokenIterator {
        return TokenIterator{
            .tokens = tokens,
            .index = 0,
        };
    }

    /// Steps forward to the next token and returns it.
    ///
    /// If out of bounds, returns the last token (usually end-of-statement)
    pub fn next(self: *TokenIterator) Token {
        if (self.index >= self.tokens.len) {
            return self.tokens[self.tokens.len - 1];
        }
        defer self.index += 1;
        return self.tokens[self.index];
    }

    /// Returns the token `steps` steps ahead of the current index.
    ///
    /// To peek the next token, use `peek(1)`.
    /// To peek the current token, use `peek(0)`.
    ///
    /// If out of bounds, returns the last token (usually end-of-statement)
    pub fn peek(self: TokenIterator, steps: usize) Token {
        if (self.index == 0 and steps == 0) @panic("Cannot peek at 0 before the start of the iterator");
        const i: usize = self.index + steps - 1;
        if (i >= self.tokens.len) {
            return self.tokens[self.tokens.len - 1];
        }

        return self.tokens[i];
    }

    /// Checks if the next token matches the given type.
    /// If so, it consumes the token.
    pub fn match(self: *TokenIterator, t: Token.Type) bool {
        if (self.peek(1).is(t)) {
            _ = self.next();
            return true;
        }
        return false;
    }

    /// Returns the amount of tokens left to iterate.
    pub fn remaining(self: TokenIterator) usize {
        return self.tokens.len - self.index;
    }

    /// Resets the iterator to the beginning as if it was just created.
    pub fn reset(self: *TokenIterator) void {
        self.index = 0;
    }
};
