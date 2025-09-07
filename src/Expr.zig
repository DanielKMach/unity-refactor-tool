const std = @import("std");
const core = @import("core");

const log = std.log.scoped(.expr_parser);

const Expr = @This();

const Location = core.Token.Location;
const ParseFn = fn (*core.parsing.Tokenizer.TokenIterator, std.mem.Allocator) std.mem.Allocator.Error!core.results.ParseResult(*Expr);

pub const Value = @import("expr/value.zig").Value;
pub const Class = @import("expr/class.zig").Class;
pub const eval = @import("expr/eval.zig");

pub const RunEnv = struct {
    allocator: std.mem.Allocator,
    vars: *const std.StringHashMap(Value),
};

loc: Location,
class: Class,

pub fn format(value: Expr, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    return value.class.format(writer);
}

/// Evaluates the expression in the given environment.
///
/// May leak memory if not used with an arena allocator.
pub const evaluate = eval.evaluate;

/// Evaluates the expression in a temporary environment, duplicating the result into the original environment's allocator.
///
/// Frees any temporary allocations made during evaluation.
pub fn evaluateAuto(self: *Expr, env: RunEnv) anyerror!core.results.RuntimeResult(Value) {
    var buf: [1024 * 1024]u8 = undefined; // 1 MiB
    var stack = std.heap.FixedBufferAllocator.init(&buf);

    const new_env = RunEnv{
        .allocator = stack.allocator(),
        .vars = env.vars,
    };

    return switch (try self.evaluate(new_env)) {
        .ok => |value| .OK(try value.dupe(env.allocator)),
        .err => |err| .ERR(err),
    };
}

pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) std.mem.Allocator.Error!core.results.ParseResult(*Expr) {
    return parseAssignment(tokens, allocator);
}

/// Recursively frees any allocations made when parsing the expression.
pub fn cleanup(self: *Expr, allocator: std.mem.Allocator) void {
    switch (self.class) {
        .literal => |l| {
            l.token.cleanup(allocator);
        },
        .unary => |u| {
            u.operand.cleanup(allocator);
            u.op.cleanup(allocator);
        },
        .binary => |b| {
            b.left.cleanup(allocator);
            b.right.cleanup(allocator);
            b.op.cleanup(allocator);
        },
        .grouping => |g| g.expr.cleanup(allocator),
    }
    allocator.destroy(self);
    self.* = undefined;
}

fn initLiteral(loc: Location, class: Class.Literal) Expr {
    return Expr{
        .loc = loc,
        .class = .{ .literal = class },
    };
}

fn initUnary(loc: Location, class: Class.Unary) Expr {
    return Expr{
        .loc = loc,
        .class = .{ .unary = class },
    };
}

fn initBinary(loc: Location, class: Class.Binary) Expr {
    return Expr{
        .loc = loc,
        .class = .{ .binary = class },
    };
}

fn initGrouping(loc: Location, class: Class.Grouping) Expr {
    return Expr{
        .loc = loc,
        .class = .{ .grouping = class },
    };
}

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
                const loc: Location = .merge(&.{ left.loc, right.loc });
                expr.* = .initBinary(loc, .{
                    .left = left,
                    .op = try t.dupe(allocator),
                    .right = right,
                });
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
                const loc: Location = .merge(&.{ left.loc, right.loc });
                expr.* = .initBinary(loc, .{
                    .left = left,
                    .op = try t.dupe(allocator),
                    .right = right,
                });
                left = expr;
            }
            return .OK(left);
        }
    }).parse;
}

fn unaryParseFunc(next_call: *const ParseFn, expected_tokens: []const core.Token.Type) ParseFn {
    return (struct {
        pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
            if (tokens.matchAny(expected_tokens)) |t| {
                const operand = switch (try @This().parse(tokens, allocator)) {
                    .ok => |expr| expr,
                    .err => |err| return .ERR(err),
                };
                const expr = try allocator.create(Expr);
                const loc: Location = .merge(&.{ operand.loc, t.loc });
                expr.* = .initUnary(loc, .{
                    .op = try t.dupe(allocator),
                    .operand = operand,
                });
                return .OK(expr);
            }
            return try next_call(tokens, allocator);
        }
    }).parse;
}

const parseAssignment = uniqueBinaryParseFunc(parseOr, &.{.equal});
const parseOr = l2rBinaryParseFunc(parseAnd, &.{.OR});
const parseAnd = l2rBinaryParseFunc(parseEquality, &.{.AND});
const parseEquality = l2rBinaryParseFunc(parseComparison, &.{ .equal_equal, .bang_equal });
const parseComparison = l2rBinaryParseFunc(parseTerm, &.{ .greater, .greater_equal, .less, .less_equal });
const parseTerm = l2rBinaryParseFunc(parseFactor, &.{ .plus, .minus });
const parseFactor = l2rBinaryParseFunc(parseNullCoalesce, &.{ .star, .slash, .percentage });
const parseNullCoalesce = l2rBinaryParseFunc(parseUnary, &.{.question_question});
const parseAccess = l2rBinaryParseFunc(parseValue, &.{.dot});
const parseUnary = unaryParseFunc(parseAccess, &.{ .NOT, .minus });

fn parseValue(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(*Expr) {
    if (tokens.matchAny(&.{ .string, .literal, .number })) |t| {
        const expr = try allocator.create(Expr);
        expr.* = .initLiteral(t.loc, .{ .token = try t.dupe(allocator) });
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
        const loc: Location = .merge(&.{ left_paren.loc, right_paren.loc });
        expr.* = .initGrouping(loc, .{ .expr = group });
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
