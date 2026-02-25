const std = @import("std");
const core = @import("core");
const log = std.log.scoped(.ast_parser);

const Expr = core.Expr;
const TokenIterator = core.Token.Iterator;

const ParseFn = fn (*TokenIterator, Env) core.ParseAllocError!*Expr;

pub const Env = struct {
    allocator: std.mem.Allocator,
    diag: *core.ParseDiagnostics,

    pub fn err(self: Env, p: core.ParseProblem) core.ParseDiagnostics.Error {
        return self.diag.push(p);
    }
};

pub fn parse(tokens: *TokenIterator, env: Env) core.ParseAllocError!*Expr {
    const expr = try assignment(tokens, env);
    log.info("Parsed expression {f}", .{expr});
    return expr;
}

/// Generates a function that parses right-to-left ternary expressions.
fn genTernaryFunc(next_call: *const ParseFn) ParseFn {
    return (struct {
        pub fn parse(tokens: *TokenIterator, env: Env) core.ParseAllocError!*Expr {
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
        pub fn parse(tokens: *TokenIterator, env: Env) core.ParseAllocError!*Expr {
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
        pub fn parse(tokens: *TokenIterator, env: Env) core.ParseAllocError!*Expr {
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

fn assignment(tokens: *TokenIterator, env: Env) core.ParseAllocError!*Expr {
    var left = try ternary(tokens, env);
    if (tokens.consumeAny(&.{
        .equal,
        .plus_equal,
        .minus_equal,
        .star_equal,
        .slash_equal,
        .colon_equal,
    })) |t| switch (left.*) {
        .property, .variable, .access, .indexing => {
            var op = t;
            var right = try assignment(tokens, env);
            switch (t.value) {
                .equal, .colon_equal => {},
                .plus_equal, .minus_equal, .star_equal, .slash_equal => {
                    // Desugar `x += y` to `x = x + y`
                    const v: core.Token.Value = switch (t.value) {
                        .plus_equal => .plus,
                        .minus_equal => .minus,
                        .star_equal => .star,
                        .slash_equal => .slash,
                        else => unreachable,
                    };
                    const unroll = try env.allocator.create(Expr);
                    unroll.* = .{ .binary = .{
                        .left = try left.dupe(env.allocator),
                        .op = .new(v, t.loc),
                        .right = right,
                    } };
                    right = unroll;
                    op = .new(.equal, t.loc);
                },
                else => unreachable,
            }
            const expr = try env.allocator.create(Expr);
            expr.* = .{ .assignment = .{
                .target = left,
                .op = try op.dupe(env.allocator),
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
fn vaif(tokens: *TokenIterator, env: Env) core.ParseAllocError!*Expr {
    var left = if (tokens.consumeAny(&.{ .literal, .variable })) |t| blk: {
        const varprop: *Expr = try env.allocator.create(Expr);
        errdefer env.allocator.destroy(varprop);
        varprop.* = switch (t.value) {
            .literal => .{ .property = .{
                .name = try t.dupe(env.allocator),
            } },
            .variable => .{ .variable = .{
                .name = try t.dupe(env.allocator),
            } },
            else => unreachable,
        };
        break :blk varprop;
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
        } else if (tokens.match(.left_bracket)) {
            const index = try parse(tokens, env);
            const rb = try tokens.grab(.right_bracket, env.diag);
            const expr = try env.allocator.create(Expr);
            expr.* = .{ .indexing = .{
                .base = left,
                .index = index,
                .bracket = try rb.dupe(env.allocator),
            } };
            left = expr;
        } else if (tokens.match(.left_paren)) {
            var args = std.ArrayList(*Expr).empty;
            defer args.deinit(env.allocator);
            errdefer for (args.items) |arg| arg.cleanup(env.allocator);

            while (!tokens.match(.right_paren)) {
                {
                    const arg = try parse(tokens, env);
                    errdefer arg.cleanup(env.allocator);
                    try args.append(env.allocator, arg);
                }
                const end = try tokens.grabAny(&.{ .comma, .right_paren }, env.diag);
                if (end.is(.right_paren)) break;
            }
            const rp = tokens.peek(0);
            std.debug.assert(rp.is(.right_paren));

            const expr = try env.allocator.create(Expr);
            errdefer env.allocator.destroy(expr);

            expr.* = .{ .call = .{
                .callee = left,
                .args = try args.toOwnedSlice(env.allocator),
                .paren = try rp.dupe(env.allocator),
            } };
            left = expr;
        } else break;
    }
    return left;
}

fn value(tokens: *TokenIterator, env: Env) core.ParseAllocError!*Expr {
    if (tokens.consumeAny(&.{ .string, .number, .NIL })) |t| {
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
    } else if (tokens.consume(.left_brace)) |lb| {
        var children = std.ArrayList(*Expr).empty;
        defer children.deinit(env.allocator);

        while (!tokens.match(.right_brace)) {
            const child = try parse(tokens, env);
            errdefer child.cleanup(env.allocator);
            try children.append(env.allocator, child);
            const end = try tokens.grabAny(&.{ .semicolon, .right_brace }, env.diag);
            if (end.is(.right_brace)) break;
        }
        const rb = tokens.peek(0);
        std.debug.assert(rb.is(.right_brace));

        const expr = try env.allocator.create(Expr);
        errdefer env.allocator.destroy(expr);
        expr.* = .{ .block = .{
            .lbrace = try lb.dupe(env.allocator),
            .rbrace = try rb.dupe(env.allocator),
            .children = try children.toOwnedSlice(env.allocator),
        } };
        return expr;
    } else {
        return env.err(.{ .unexpected_token = .{
            .found = tokens.peek(1),
            .expected = &.{ .left_paren, .literal, .string, .number, .NIL },
        } });
    }
}
