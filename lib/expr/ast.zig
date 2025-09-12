const std = @import("std");
const core = @import("core");
const log = std.log.scoped(.ast_parser);

const Expr = core.Expr;
const Location = core.Token.Location;

const ParseFn = fn (*core.parsing.Tokenizer.TokenIterator, Expr.ParseEnv) core.ParseAllocError!*Expr;

pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
    const expr = try assignment(tokens, env);
    log.info("Parsed expression {f}", .{expr});
    return expr;
}

/// Generates a function that parses right-to-left ternary expressions.
fn genTernaryFunc(next_call: *const ParseFn) ParseFn {
    return (struct {
        pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
            var left = try next_call(tokens, env);
            if (tokens.match(.question)) {
                const middle = try next_call(tokens, env);
                if (!tokens.match(.colon)) {
                    return env.err(.{
                        .unexpected_token = .{
                            .found = tokens.next(),
                            .expected = &.{.colon},
                        },
                    });
                }
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
        pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
            var left = try next_call(tokens, env);
            while (tokens.matchAny(expected_tokens)) |t| {
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
        pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
            if (tokens.matchAny(expected_tokens)) |t| {
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

fn assignment(tokens: *core.parsing.Tokenizer.TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
    var left = try ternary(tokens, env);
    if (tokens.match(.equal)) {
        switch (left.*) {
            .variable, .access => {},
            else => return env.err(.{ .invalid_assignment_target = .{
                .location = left.loc(),
            } }),
        }
        const right = try assignment(tokens, env);
        const expr = try env.allocator.create(Expr);
        expr.* = .{ .assignment = .{
            .target = left,
            .value = right,
        } };
        left = expr;
    }
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
fn vaif(tokens: *core.parsing.Tokenizer.TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
    var left = if (tokens.matchAny(&.{.literal})) |t| blk: {
        const varr: *Expr = try env.allocator.create(Expr);
        varr.* = .{ .variable = .{
            .name = try t.dupe(env.allocator),
        } };
        break :blk varr;
    } else return try value(tokens, env);

    while (true) {
        if (tokens.match(.dot)) {
            if (tokens.matchAny(&.{.literal})) |t| {
                const expr = try env.allocator.create(Expr);
                expr.* = .{ .access = .{
                    .base = left,
                    .property = try t.dupe(env.allocator),
                } };
                left = expr;
            } else return env.err(.{ .unexpected_token = .{
                .found = tokens.next(),
                .expected = &.{.literal},
            } });
        }
        // else if (tokens.match(.left_bracket)) {} TODO: indexing
        // else if (tokens.match(.left_paren)) {} TODO: function call
        else break;
    }
    return left;
}

fn value(tokens: *core.parsing.Tokenizer.TokenIterator, env: Expr.ParseEnv) core.ParseAllocError!*Expr {
    if (tokens.matchAny(&.{ .string, .number })) |t| {
        const expr = try env.allocator.create(Expr);
        expr.* = .{ .literal = .{
            .token = try t.dupe(env.allocator),
        } };
        return expr;
    } else if (tokens.match(.left_paren)) {
        const left_paren = tokens.peek(0);
        const group = try parse(tokens, env);
        if (!tokens.match(.right_paren)) {
            return env.err(.{
                .unexpected_token = .{
                    .found = tokens.next(),
                    .expected = &.{.right_paren},
                },
            });
        }
        const right_paren = tokens.peek(0);
        const expr = try env.allocator.create(Expr);
        expr.* = .{ .grouping = .{
            .loc = .merge(&.{ left_paren.loc, right_paren.loc }),
            .expr = group,
        } };
        return expr;
    } else {
        return env.err(.{
            .unexpected_token = .{
                .found = tokens.next(),
                .expected = &.{ .left_paren, .literal, .string, .number },
            },
        });
    }
}
