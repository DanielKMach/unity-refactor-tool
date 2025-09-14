const std = @import("std");
const core = @import("core");
const log = std.log.scoped(.ast_parser);

const Expr = core.Expr;
const TokenIterator = core.Token.Iterator;

const ParseFn = fn (*TokenIterator, Expr.ParseEnv) core.ParseAllocError!*Expr;

pub fn parse(tokens: *TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
    const expr = try assignment(tokens, env);
    log.info("Parsed expression {f}", .{expr});
    return expr;
}

/// Generates a function that parses right-to-left ternary expressions.
fn genTernaryFunc(next_call: *const ParseFn) ParseFn {
    return (struct {
        pub fn parse(tokens: *TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
            var left = try next_call(tokens, env);
            if (tokens.match(.question)) {
                const middle = try next_call(tokens, env);
                _ = try tokens.grab(.colon, env.diag);
                const right = try @This().parse(tokens, env);
                const expr = try env.allocator.create(Expr);
                expr.* = .{ .ternary = .{
                    .left = left,
                    .middle = middle,
                    .right = right,
                } };
                left = expr;
            }
            return left;
        }
    }).parse;
}

/// Generates a function that parses left-to-right binary expressions.
fn genBinaryFunc(next_call: *const ParseFn, expected_tokens: []const core.Token.Type) ParseFn {
    return (struct {
        pub fn parse(tokens: *TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
            var left = try next_call(tokens, env);
            while (tokens.consumeAny(expected_tokens)) |t| {
                const right = try next_call(tokens, env);
                const expr = try env.allocator.create(Expr);
                expr.* = .{ .binary = .{
                    .left = left,
                    .op = try t.dupe(env.allocator),
                    .right = right,
                } };
                left = expr;
            }
            return left;
        }
    }).parse;
}

/// Generates a function that parses prefixed unary expressions.
fn genUnaryFunc(next_call: *const ParseFn, expected_tokens: []const core.Token.Type) ParseFn {
    return (struct {
        pub fn parse(tokens: *TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
            if (tokens.consumeAny(expected_tokens)) |t| {
                const operand = try @This().parse(tokens, env);
                const expr = try env.allocator.create(Expr);
                expr.* = .{ .unary = .{
                    .op = try t.dupe(env.allocator),
                    .operand = operand,
                } };
                return expr;
            }
            return try next_call(tokens, env);
        }
    }).parse;
}

fn assignment(tokens: *TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
    var left = try ternary(tokens, env);
    if (tokens.match(.equal)) switch (left.*) {
        .variable, .access => {
            const right = try assignment(tokens, env);
            const expr = try env.allocator.create(Expr);
            expr.* = .{ .assignment = .{
                .target = left,
                .value = right,
            } };
            left = expr;
        },
        else => return env.err(.{ .invalid_assignment_target = .{
            .location = left.loc(),
        } }),
    };
    return left;
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
fn vaif(tokens: *TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
    var left = if (tokens.consume(.literal)) |t| blk: {
        const varr: *Expr = try env.allocator.create(Expr);
        varr.* = .{ .variable = .{
            .name = try t.dupe(env.allocator),
        } };
        break :blk varr;
    } else return try value(tokens, env);

    while (true) {
        if (tokens.match(.dot)) {
            const t = try tokens.grab(.literal, env.diag);
            const expr = try env.allocator.create(Expr);
            expr.* = .{ .access = .{
                .base = left,
                .property = try t.dupe(env.allocator),
            } };
            left = expr;
        }
        // else if (tokens.match(.left_bracket)) {} TODO: indexing
        // else if (tokens.match(.left_paren)) {} TODO: function call
        else break;
    }
    return left;
}

fn value(tokens: *TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
    if (tokens.consumeAny(&.{ .string, .number })) |t| {
        const expr = try env.allocator.create(Expr);
        expr.* = .{ .literal = .{
            .token = try t.dupe(env.allocator),
        } };
        return expr;
    } else if (tokens.consume(.left_paren)) |lp| {
        const group = try parse(tokens, env);
        const rp = try tokens.grab(.right_paren, env.diag);
        const expr = try env.allocator.create(Expr);
        expr.* = .{ .grouping = .{
            .loc = .merge(&.{ lp.loc, rp.loc }),
            .expr = group,
        } };
        return expr;
    } else {
        return env.err(.{
            .unexpected_token = .{
                .found = tokens.peek(1),
                .expected = &.{ .left_paren, .literal, .string, .number },
            },
        });
    }
}
