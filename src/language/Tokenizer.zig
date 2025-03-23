const std = @import("std");
const core = @import("root");
const language = core.language;
const errors = core.errors;
const log = std.log.scoped(.usql_tokenizer);

const This = @This();

pub fn tokenize(expression: []const u8, allocator: std.mem.Allocator) !errors.CompilerError(TokenIterator) {
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
            try list.append(Token.new(.literal_string, expression[si + 1 .. i]));
            si = i + 1;
            continue;
        }
    }

    for (list.items) |tkn| {
        log.debug("Token: ({s}, '{s}')", .{ @tagName(tkn.type), tkn.value });
    }

    return .OK(.{ .tokens = try list.toOwnedSlice() });
}

pub const Token = struct {
    type: TokenType,
    value: []const u8,

    pub fn new(typ: TokenType, value: []const u8) Token {
        return Token{ .type = typ, .value = value };
    }

    pub fn eql(self: Token, other: Token) bool {
        return self.type == other.type and std.mem.eql(u8, self.value, other.value);
    }

    pub fn is(self: Token, typ: TokenType, value: []const u8) bool {
        return self.type == typ and std.mem.eql(u8, self.value, value);
    }

    pub fn isType(self: Token, typ: TokenType) bool {
        return self.type == typ;
    }

    pub fn hash(self: Token) u64 {
        const str = std.hash.RapidHash.hash(0, self.value);
        const typ = std.hash.RapidHash.hash(0, &.{@intFromEnum(self.type)});
        return @addWithOverflow(str, typ)[0];
    }
};

pub const TokenType = enum {
    keyword,
    operator,
    literal_number,
    literal_string,
    literal,
};

pub const TokenIterator = struct {
    tokens: []Token,
    index: isize = -1,

    pub fn next(self: *TokenIterator) ?Token {
        if (self.index + 1 >= self.tokens.len) {
            return null;
        }
        self.index += 1;
        return self.tokens[@intCast(self.index)];
    }

    pub fn peek(self: TokenIterator, steps: isize) ?Token {
        const i = self.index + steps;
        if (i >= self.tokens.len or i < 0) {
            return null;
        }
        return self.tokens[@intCast(i)];
    }

    pub fn len(self: TokenIterator) usize {
        return self.tokens.len - self.index;
    }
};
