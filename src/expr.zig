const std = @import("std");
const core = @import("core");

const log = std.log.scoped(.expr_parser);

const ParseFn = fn (*core.parsing.Tokenizer.TokenIterator, std.mem.Allocator) std.mem.Allocator.Error!core.results.ParseResult(*Expr);

pub const Grouping = @import("expr/Grouping.zig");
pub const Literal = @import("expr/Literal.zig");
pub const Binary = @import("expr/Binary.zig");
pub const Unary = @import("expr/Unary.zig");

pub const Expr = union(enum) {
    grouping: Grouping,
    literal: Literal,
    binary: Binary,
    unary: Unary,

    pub fn format(value: Expr, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (value) {
            .grouping => |g| try writer.print("(group {})", .{g.expr}),
            .literal => |l| try writer.print("{s}", .{l.token.value}),
            .binary => |b| try writer.print("({s} {} {})", .{ b.op.value, b.left, b.right }),
            .unary => |u| try writer.print("({s} {})", .{ u.op.value, u.operand }),
        }
    }
};

pub fn makeUniqueBinaryParseFunc(next_call: ParseFn, expected_tokens: []const core.Token.Type) ParseFn {
    return (struct {
        pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
            var left = switch (try next_call(tokens, allocator)) {
                .ok => |expr| expr,
                .err => |err| return .ERR(err),
            };
            if (tokens.matchAny(expected_tokens)) |t| {
                const right = switch (try next_call(tokens, allocator)) {
                    .ok => |expr| expr,
                    .err => |err| return .ERR(err),
                };
                const expr = try allocator.create(Expr);
                expr.* = .{ .binary = .init(left, t, right) };
                left = expr;
            }
            if (tokens.matchAny(expected_tokens)) |t| {
                return .ERR(.{
                    .unexpected_token = .{
                        .found = t,
                        .expected = expected_tokens,
                    },
                });
            }
            return .OK(left);
        }
    }).parse;
}

// TODO: see if this func works (could be useful to reduce code)
pub fn makeL2RBinaryParseFunc(next_call: ParseFn, expected_tokens: []const core.Token.Type) ParseFn {
    return (struct {
        pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
            var left = switch (next_call(tokens, allocator)) {
                .ok => |expr| expr,
                .err => |err| return .ERR(err),
            };
            while (tokens.matchAny(expected_tokens)) |t| {
                const right = switch (next_call(tokens, allocator)) {
                    .ok => |expr| expr,
                    .err => |err| return .ERR(err),
                };
                const expr = try allocator.create(Expr);
                expr.* = .{ .binary = Binary{
                    .left = left,
                    .op = t,
                    .right = right,
                } };
                left = expr;
            }
            return .OK(left);
        }
    }).parse;
}

// Garantees that, if an error occurs, all allocated memory is freed.
pub fn parseSafe(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
    var arena = std.heap.ArenaAllocator.init(allocator);
    const new_alloc = arena.allocator();

    return switch (try parse(tokens, new_alloc)) {
        .ok => |expr| blk: {
            log.debug("{}", .{expr});
            break :blk .OK(expr);
        },
        .err => |err| blk: {
            _ = arena.reset(.free_all);
            break :blk .ERR(err);
        },
    };
}

pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) std.mem.Allocator.Error!core.results.ParseResult(*Expr) {
    return parseAssignment(tokens, allocator);
}

fn parseAssignment(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
    // TODO: handle right-to-left assignment (if not too much headache)
    var left = switch (try parseEquality(tokens, allocator)) {
        .ok => |expr| expr,
        .err => |err| return .ERR(err),
    };
    log.debug("peek = {s}", .{@tagName(tokens.peek(1).value)});
    if (tokens.matchAny(&.{.equal})) |t| {
        const right = switch (try parseEquality(tokens, allocator)) {
            .ok => |expr| expr,
            .err => |err| return .ERR(err),
        };
        const expr = try allocator.create(Expr);
        expr.* = .{ .binary = .init(left, t, right) };
        left = expr;
    }
    if (tokens.matchAny(&.{.equal})) |t| {
        return .ERR(.{
            .unexpected_token = .{
                .found = t,
                .expected = &.{.equal},
            },
        });
    }
    return .OK(left);
}

fn parseEquality(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
    var left = switch (try parseComparison(tokens, allocator)) {
        .ok => |expr| expr,
        .err => |err| return .ERR(err),
    };
    while (tokens.matchAny(&.{ .equal_equal, .bang_equal })) |t| {
        const right = switch (try parseComparison(tokens, allocator)) {
            .ok => |expr| expr,
            .err => |err| return .ERR(err),
        };
        const expr = try allocator.create(Expr);
        expr.* = .{ .binary = Binary{
            .left = left,
            .op = t,
            .right = right,
        } };
        left = expr;
    }
    return .OK(left);
}

fn parseComparison(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
    var left = switch (try parseTerm(tokens, allocator)) {
        .ok => |expr| expr,
        .err => |err| return .ERR(err),
    };
    while (tokens.matchAny(&.{ .greater, .greater_equal, .less, .less_equal })) |t| {
        const right = switch (try parseTerm(tokens, allocator)) {
            .ok => |expr| expr,
            .err => |err| return .ERR(err),
        };
        const expr = try allocator.create(Expr);
        expr.* = .{ .binary = Binary{
            .left = left,
            .op = t,
            .right = right,
        } };
        left = expr;
    }
    return .OK(left);
}

fn parseTerm(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
    var left = switch (try parseFactor(tokens, allocator)) {
        .ok => |expr| expr,
        .err => |err| return .ERR(err),
    };
    while (tokens.matchAny(&.{ .plus, .minus })) |t| {
        const right = switch (try parseFactor(tokens, allocator)) {
            .ok => |expr| expr,
            .err => |err| return .ERR(err),
        };
        const expr = try allocator.create(Expr);
        expr.* = .{ .binary = Binary{
            .left = left,
            .op = t,
            .right = right,
        } };
        left = expr;
    }
    return .OK(left);
}

fn parseFactor(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
    var left = switch (try parseUnary(tokens, allocator)) {
        .ok => |expr| expr,
        .err => |err| return .ERR(err),
    };
    while (tokens.matchAny(&.{ .star, .slash })) |t| {
        const right = switch (try parseUnary(tokens, allocator)) {
            .ok => |expr| expr,
            .err => |err| return .ERR(err),
        };
        const expr = try allocator.create(Expr);
        expr.* = .{ .binary = Binary{
            .left = left,
            .op = t,
            .right = right,
        } };
        left = expr;
    }
    return .OK(left);
}

fn parseUnary(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
    if (tokens.matchAny(&.{ .NOT, .minus })) |t| {
        const operand = switch (try parseUnary(tokens, allocator)) {
            .ok => |expr| expr,
            .err => |err| return .ERR(err),
        };
        const expr = try allocator.create(Expr);
        expr.* = .{ .unary = Unary{
            .op = t,
            .operand = operand,
        } };
        return .OK(expr);
    }
    return try parseAccess(tokens, allocator);
}

fn parseAccess(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
    var left = switch (try parseValue(tokens, allocator)) {
        .ok => |expr| expr,
        .err => |err| return .ERR(err),
    };
    while (tokens.matchAny(&.{.dot})) |t| {
        const right = switch (try parseValue(tokens, allocator)) {
            .ok => |expr| expr,
            .err => |err| return .ERR(err),
        };
        const expr = try allocator.create(Expr);
        expr.* = .{ .binary = Binary{
            .left = left,
            .op = t,
            .right = right,
        } };
        left = expr;
    }
    return .OK(left);
}

fn parseValue(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
    if (tokens.matchAny(&.{ .string, .literal, .number })) |t| {
        log.debug("Parsed value: {s}", .{@tagName(t.value)});
        const expr = try allocator.create(Expr);
        expr.* = .{ .literal = .init(t) };
        log.debug("Parsed literal: {}", .{expr});
        return .OK(expr);
    } else if (tokens.match(.left_paren)) {
        log.debug("Parsed value: left_paren", .{});
        const group = switch (try parse(tokens, allocator)) {
            .ok => |grouping| grouping,
            .err => |err| return .ERR(err),
        };
        if (!tokens.match(.right_paren)) {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tokens.next(),
                    .expected = &.{.right_paren},
                },
            });
        }
        const expr = try allocator.create(Expr);
        expr.* = .{ .grouping = .init(group) };
        return .OK(expr);
    } else {
        return .ERR(.{
            .unexpected_token = .{
                .found = tokens.next(),
                .expected = &.{ .left_paren, .literal, .string, .number },
            },
        });
    }
}
