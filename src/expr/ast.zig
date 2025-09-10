const std = @import("std");
const core = @import("core");
const log = std.log.scoped(.ast_parser);

const Expr = core.Expr;
const Location = core.Token.Location;

const ParseFn = fn (*core.parsing.Tokenizer.TokenIterator, std.mem.Allocator) std.mem.Allocator.Error!core.results.ParseResult(*Expr);

pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) std.mem.Allocator.Error!core.results.ParseResult(*Expr) {
    const result = try assignment(tokens, allocator);
    if (result == .ok) log.info("Parsed expression {f}", .{result.ok});
    return result;
}

/// Generates a function that parses right-to-left ternary expressions.
fn genTernaryFunc(next_call: *const ParseFn) ParseFn {
    return (struct {
        pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
            var left = switch (try next_call(tokens, allocator)) {
                .ok => |expr| expr,
                .err => |err| return .ERR(err),
            };
            if (tokens.match(.question)) {
                const middle = switch (try next_call(tokens, allocator)) {
                    .ok => |expr| expr,
                    .err => |err| return .ERR(err),
                };
                if (!tokens.match(.colon)) {
                    return .ERR(.{
                        .unexpected_token = .{
                            .found = tokens.next(),
                            .expected = &.{.colon},
                        },
                    });
                }
                const right = switch (try @This().parse(tokens, allocator)) {
                    .ok => |expr| expr,
                    .err => |err| return .ERR(err),
                };
                const expr = try allocator.create(Expr);
                expr.* = .{ .ternary = .{
                    .left = left,
                    .middle = middle,
                    .right = right,
                } };
                left = expr;
            }
            return .OK(left);
        }
    }).parse;
}

/// Generates a function that parses left-to-right binary expressions.
fn genBinaryFunc(next_call: *const ParseFn, expected_tokens: []const core.Token.Type) ParseFn {
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
                expr.* = .{ .binary = .{
                    .left = left,
                    .op = try t.dupe(allocator),
                    .right = right,
                } };
                left = expr;
            }
            return .OK(left);
        }
    }).parse;
}

/// Generates a function that parses prefixed unary expressions.
fn genUnaryFunc(next_call: *const ParseFn, expected_tokens: []const core.Token.Type) ParseFn {
    return (struct {
        pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
            if (tokens.matchAny(expected_tokens)) |t| {
                const operand = switch (try @This().parse(tokens, allocator)) {
                    .ok => |expr| expr,
                    .err => |err| return .ERR(err),
                };
                const expr = try allocator.create(Expr);
                expr.* = .{ .unary = .{
                    .op = try t.dupe(allocator),
                    .operand = operand,
                } };
                return .OK(expr);
            }
            return try next_call(tokens, allocator);
        }
    }).parse;
}

fn assignment(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
    var left = switch (try ternary(tokens, allocator)) {
        .ok => |expr| expr,
        .err => |err| return .ERR(err),
    };
    if (tokens.match(.equal)) {
        switch (left.*) {
            .variable, .access => {},
            else => @panic("TODO: Invalid assignment target"),
        }
        const right = switch (try assignment(tokens, allocator)) {
            .ok => |expr| expr,
            .err => |err| return .ERR(err),
        };
        const expr = try allocator.create(Expr);
        expr.* = .{ .assignment = .{
            .target = left,
            .value = right,
        } };
        left = expr;
    }
    return .OK(left);
}

const ternary = genTernaryFunc(OR);
const OR = genBinaryFunc(AND, &.{.OR});
const AND = genBinaryFunc(equality, &.{.AND});
const equality = genBinaryFunc(comparison, &.{ .equal_equal, .bang_equal });
const comparison = genBinaryFunc(term, &.{ .greater, .greater_equal, .less, .less_equal });
const term = genBinaryFunc(factor, &.{ .plus, .minus });
const factor = genBinaryFunc(nullCoalesce, &.{ .star, .slash, .percentage });
const nullCoalesce = genBinaryFunc(unary, &.{.question_question});
const unary = genUnaryFunc(vaif, &.{ .NOT, .minus });

// Parse variable, access, indexing, function call or value
fn vaif(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) std.mem.Allocator.Error!core.results.ParseResult(*Expr) {
    var left = if (tokens.matchAny(&.{.literal})) |t| blk: {
        const varr: *Expr = try allocator.create(Expr);
        varr.* = .{ .variable = .{
            .name = try t.dupe(allocator),
        } };
        break :blk varr;
    } else return try value(tokens, allocator);

    while (true) {
        if (tokens.match(.dot)) {
            if (tokens.matchAny(&.{.literal})) |t| {
                const expr = try allocator.create(Expr);
                expr.* = .{ .access = .{
                    .base = left,
                    .property = try t.dupe(allocator),
                } };
                left = expr;
            } else return .ERR(.{
                .unexpected_token = .{
                    .found = tokens.next(),
                    .expected = &.{.literal},
                },
            });
        }
        // else if (tokens.match(.left_bracket)) {} TODO: indexing
        // else if (tokens.match(.left_paren)) {} TODO: function call
        else break;
    }
    return .OK(left);
}

fn value(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) std.mem.Allocator.Error!core.results.ParseResult(*Expr) {
    if (tokens.matchAny(&.{ .string, .number })) |t| {
        const expr = try allocator.create(Expr);
        expr.* = .{ .literal = .{
            .token = try t.dupe(allocator),
        } };
        return .OK(expr);
    } else if (tokens.match(.left_paren)) {
        const left_paren = tokens.peek(0);
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
        const right_paren = tokens.peek(0);
        const expr = try allocator.create(Expr);
        expr.* = .{ .grouping = .{
            .loc = .merge(&.{ left_paren.loc, right_paren.loc }),
            .expr = group,
        } };
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
