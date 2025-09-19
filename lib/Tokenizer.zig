const std = @import("std");
const core = @import("core");
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

pub fn token(self: *This, diag: *core.ParseDiagnostics) core.ParseError!?Token {
    var start = self.index;
    while (self.match(whitespace ++ "#")) {
        if (self.at(self.index - 1) == '#') {
            while (self.next()) |n| {
                if (n == '\n') break;
            }
        }
    }
    if (self.peek() == null) {
        if (self.index == self.source.len) {
            self.index += 1; // ensure we don't return eof multiple times
            return .new(.eof, .init(start, 0));
        }
        return null;
    }

    start = self.index;
    if (self.match(alphabetic ++ "_")) { // literals/keywords
        while (self.match(alphanumeric ++ "_")) {}
        const word = self.slice(start, 0);
        for (Token.keyword_list) |kw| {
            if (std.ascii.eqlIgnoreCase(word, kw[0])) {
                return .new(kw[1], .fromSlice(self.source, word));
            }
        }
        return .new(.{ .literal = word }, .fromSlice(self.source, word));
    } else if (self.match("`")) {
        while (self.next()) |c| {
            if (c == self.at(start)) {
                const word = self.slice(start + 1, -1);
                return .new(.{ .literal = word }, .fromSlice(self.source, word));
            }
        } else {
            return diag.push(.{ .never_closed_string = .{ .location = .init(start, 1) } });
        }
    } else if (self.match("$")) { //
        if (!self.match(alphabetic ++ "_")) {
            return diag.push(.{ .unexpected_character = .{
                .location = .init(start, 1),
            } });
        }
        while (self.match(alphanumeric ++ "_")) {}
        const word = self.slice(start, 0);
        return .new(.{ .variable = word[1..] }, .fromSlice(self.source, word));
    } else if (self.match("\"'")) { // strings
        while (self.next()) |c| {
            if (c == self.at(start)) {
                const str = self.slice(start + 1, -1);
                return .new(.{ .string = str }, .init(start, str.len + 2));
            }
        } else {
            return diag.push(.{ .never_closed_string = .{ .location = .init(start, 1) } });
        }
    } else if (self.match(digit)) {
        while (self.match(digit ++ ".")) {}
        const number_literal = self.slice(start, 0);
        const number = std.fmt.parseFloat(f32, number_literal) catch {
            return diag.push(.{ .invalid_number = .{ .location = .fromSlice(self.source, number_literal) } });
        };
        return .new(.{ .number = number }, .fromSlice(self.source, number_literal));
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
            return .new(operator[1], .init(self.index, operator[0].len));
        } else {
            return diag.push(.{ .unexpected_character = .{ .location = .init(self.index, 1) } });
        }
    }
}

/// Tokenizes the given expression into a slice of tokens.
///
/// The slice is owned by the caller.
pub fn tokenize(expression: []const u8, allocator: std.mem.Allocator, diag: *core.ParseDiagnostics) core.ParseAllocError![]Token {
    core.profiling.begin(tokenize);
    defer core.profiling.stop();

    var list = try std.ArrayList(Token).initCapacity(allocator, 16);
    defer list.deinit(allocator);

    var tokenizer = This.init(expression);
    while (try tokenizer.token(diag)) |tkn| {
        try list.append(allocator, tkn);
    }

    for (list.items) |tkn| {
        log.info("Token({s}, <{s}>)", .{ @tagName(tkn.value), tkn.loc.lexeme(expression) });
    }

    return try list.toOwnedSlice(allocator);
}
