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

/// The difference between this and L2R is that this func will return an error if the matching operation is found twice
/// in the same expression without explicit parentheses.
///
/// This is the case for assignment operations, where it should be right-to-left, but since
/// there is no easy way to find the end of the expression from the iterator, I simply
/// decided that it needed explicit parentheses to be valid.
fn uniqueBinaryParseFunc(next_call: *const ParseFn, expected_tokens: []const core.Token.Type) ParseFn {
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

/// Generates a function that parses binary expressions from left to right.
fn l2rBinaryParseFunc(next_call: *const ParseFn, expected_tokens: []const core.Token.Type) ParseFn {
    return (struct {
        pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
            var left = switch (try next_call(tokens, allocator)) {
                .ok => |expr| expr,
                .err => |err| return .ERR(err),
            };
            while (tokens.matchAny(expected_tokens)) |t| {
                const right = switch (try next_call(tokens, allocator)) {
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

/// Unused. TODO: fix dependency loop.
fn unaryParseFunc(self: *const ParseFn, next_call: *const ParseFn, expected_tokens: []const core.Token.Type) ParseFn {
    return (struct {
        pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
            if (tokens.matchAny(expected_tokens)) |t| {
                const operand = switch (try self(tokens, allocator)) {
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
            return try next_call(tokens, allocator);
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

const parseAssignment = uniqueBinaryParseFunc(parseOr, &.{.equal});
const parseOr = l2rBinaryParseFunc(parseAnd, &.{.OR});
const parseAnd = l2rBinaryParseFunc(parseEquality, &.{.AND});
const parseEquality = l2rBinaryParseFunc(parseComparison, &.{ .equal_equal, .bang_equal });
const parseComparison = l2rBinaryParseFunc(parseTerm, &.{ .greater, .greater_equal, .less, .less_equal });
const parseTerm = l2rBinaryParseFunc(parseFactor, &.{ .plus, .minus });
const parseFactor = l2rBinaryParseFunc(parseUnary, &.{ .star, .slash });
const parseAccess = l2rBinaryParseFunc(parseValue, &.{.dot});

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

fn parseValue(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
    if (tokens.matchAny(&.{ .string, .literal, .number })) |t| {
        const expr = try allocator.create(Expr);
        expr.* = .{ .literal = .init(t) };
        return .OK(expr);
    } else if (tokens.match(.left_paren)) {
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
