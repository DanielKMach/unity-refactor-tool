const std = @import("std");
const common = @import("common.zig");
const log = std.log.scoped(.tokenizer);

const This = @This();
const CompilerError = @import("errors.zig").CompilerError(TokenIterator);
pub const TokenIterator = []Token;

pub const Token = struct {
    type: TokenType,
    value: []const u8,

    pub fn new(typ: TokenType, value: []const u8) Token {
        return Token{ .type = typ, .value = value };
    }
};

pub const TokenType = enum {
    keyword,
    operator,
    literal_number,
    literal_string,
    literal,
};

allocator: std.mem.Allocator,

pub fn tokenize(self: *This, expression: []const u8) !CompilerError {
    var list = std.ArrayList(Token).init(self.allocator);
    defer list.deinit();

    var si: usize = 0;
    var i: usize = 0;
    while (i < expression.len) : (i += 1) {
        const char = expression[i];
        log.info("char at {d} = {u}", .{ i, char });
        if (common.isWhitespace(char)) {
            const word = expression[si..i];
            if (si != i) {
                var tpe: TokenType = .literal;
                if (common.isKeyword(word)) {
                    tpe = .keyword;
                }
                try list.append(Token.new(tpe, word));
                log.info("{s}: {s}", .{ @tagName(tpe), word });
                si = i + 1;
            }
            si = i + 1;
            continue;
        }
        if (char == '\'' or char == '"') {
            si = i;
            i += 1;
            while (expression[i] != expression[si]) : (i += 1) {
                if (i >= expression.len - 1) {
                    return CompilerError.err(.{ .never_closed_string = .{ .index = si } });
                }
                if (expression[i] == '\\') {
                    i += 1;
                }
            }
            try list.append(Token.new(.literal_string, expression[si + 1 .. i]));
            log.info("String: {s}", .{expression[si + 1 .. i]});
            si = i + 1;
            continue;
        }
    }

    for (list.items) |tkn| {
        log.info("Token: ({s}, '{s}')", .{ @tagName(tkn.type), tkn.value });
    }

    return CompilerError.ok(try list.toOwnedSlice());
}
