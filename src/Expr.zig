const std = @import("std");
const core = @import("core");

const log = std.log.scoped(.expr_parser);

const Expr = @This();

const Location = core.Token.Location;
const ParseFn = fn (*core.parsing.Tokenizer.TokenIterator, *std.heap.MemoryPool(Expr)) std.mem.Allocator.Error!core.results.ParseResult(*Expr);

pub const ExprManaged = @import("expr/ExprManaged.zig");

pub const Grouping = @import("expr/Grouping.zig");
pub const Literal = @import("expr/Literal.zig");
pub const Binary = @import("expr/Binary.zig");
pub const Unary = @import("expr/Unary.zig");

pub const RunEnv = struct {
    allocator: std.mem.Allocator,
    vars: std.StringHashMap(Value),
};

pub const Value = union(enum) {
    pub const Type = @typeInfo(Value).@"union".tag_type orelse unreachable;

    nil,
    string: []const u8,
    number: f32,
    object: void,
    array: void,
};

pub const Class = union(enum) {
    pub const Type = @typeInfo(Class).@"union".tag_type orelse unreachable;

    grouping: Grouping,
    literal: Literal,
    binary: Binary,
    unary: Unary,

    pub fn format(value: Class, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (value) {
            .grouping => |g| try writer.print("(group {})", .{g.expr}),
            .literal => |l| try writer.print("{s}", .{l.token.value}),
            .binary => |b| try writer.print("({s} {} {})", .{ b.op.value, b.left, b.right }),
            .unary => |u| try writer.print("({s} {})", .{ u.op.value, u.operand }),
        }
    }
};

loc: Location,
class: Class,

pub fn format(value: Expr, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    return value.class.format(fmt, options, writer);
}

pub fn evaluate(self: Expr, env: RunEnv) anyerror!core.results.RuntimeResult(Value) {
    return switch (self.class) {
        else => |cls| cls.evaluate(env),
    };
}

pub fn initBinary(loc: Location, class: Binary) Expr {
    return Expr{
        .loc = loc,
        .class = .{ .binary = class },
    };
}

pub fn initLiteral(loc: Location, class: Literal) Expr {
    return Expr{
        .loc = loc,
        .class = .{ .literal = class },
    };
}

pub fn initGrouping(loc: Location, class: Grouping) Expr {
    return Expr{
        .loc = loc,
        .class = .{ .grouping = class },
    };
}

pub fn initUnary(loc: Location, class: Unary) Expr {
    return Expr{
        .loc = loc,
        .class = .{ .unary = class },
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
        pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, pool: *std.heap.MemoryPool(Expr)) !core.results.ParseResult(*Expr) {
            var left = switch (try next_call(tokens, pool)) {
                .ok => |expr| expr,
                .err => |err| return .ERR(err),
            };
            if (tokens.matchAny(expected_tokens)) |t| {
                const right = switch (try next_call(tokens, pool)) {
                    .ok => |expr| expr,
                    .err => |err| return .ERR(err),
                };
                const expr = try pool.create();
                const loc: Location = .merge(&.{ left.loc, right.loc });
                expr.* = .initBinary(loc, .init(left, t, right));
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
        pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, pool: *std.heap.MemoryPool(Expr)) !core.results.ParseResult(*Expr) {
            var left = switch (try next_call(tokens, pool)) {
                .ok => |expr| expr,
                .err => |err| return .ERR(err),
            };
            while (tokens.matchAny(expected_tokens)) |t| {
                const right = switch (try next_call(tokens, pool)) {
                    .ok => |expr| expr,
                    .err => |err| return .ERR(err),
                };
                const expr = try pool.create();
                const loc: Location = .merge(&.{ left.loc, right.loc });
                expr.* = .initBinary(loc, .init(left, t, right));
                left = expr;
            }
            return .OK(left);
        }
    }).parse;
}

/// Unused. TODO: fix dependency loop.
fn unaryParseFunc(self: *const ParseFn, next_call: *const ParseFn, expected_tokens: []const core.Token.Type) ParseFn {
    return (struct {
        pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, pool: *std.heap.MemoryPool(Expr)) !core.results.ParseResult(*Expr) {
            if (tokens.matchAny(expected_tokens)) |t| {
                const operand = switch (try self(tokens, pool)) {
                    .ok => |expr| expr,
                    .err => |err| return .ERR(err),
                };
                const expr = try pool.create(Expr);
                const loc: Location = .merge(&.{ operand.loc, t.loc });
                expr.* = .initUnary(loc, .init(t, operand));
                return .OK(expr);
            }
            return try next_call(tokens, pool);
        }
    }).parse;
}

// Garantees that, if an error occurs, all allocated memory is freed.
pub fn parseSafe(tokens: *core.parsing.Tokenizer.TokenIterator, allocator: std.mem.Allocator) !core.results.ParseResult(ExprManaged) {
    var pool = std.heap.MemoryPool(Expr).init(allocator);
    return switch (try parse(tokens, &pool)) {
        .ok => |expr| blk: {
            break :blk .OK(.{
                .pool = pool,
                .expr = expr,
            });
        },
        .err => |err| blk: {
            _ = pool.reset(.free_all);
            break :blk .ERR(err);
        },
    };
}

pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, pool: *std.heap.MemoryPool(Expr)) std.mem.Allocator.Error!core.results.ParseResult(*Expr) {
    return parseAssignment(tokens, pool);
}

const parseAssignment = uniqueBinaryParseFunc(parseOr, &.{.equal});
const parseOr = l2rBinaryParseFunc(parseAnd, &.{.OR});
const parseAnd = l2rBinaryParseFunc(parseEquality, &.{.AND});
const parseEquality = l2rBinaryParseFunc(parseComparison, &.{ .equal_equal, .bang_equal });
const parseComparison = l2rBinaryParseFunc(parseTerm, &.{ .greater, .greater_equal, .less, .less_equal });
const parseTerm = l2rBinaryParseFunc(parseFactor, &.{ .plus, .minus });
const parseFactor = l2rBinaryParseFunc(parseUnary, &.{ .star, .slash });
const parseAccess = l2rBinaryParseFunc(parseValue, &.{.dot});

fn parseUnary(tokens: *core.parsing.Tokenizer.TokenIterator, pool: *std.heap.MemoryPool(Expr)) !core.results.ParseResult(*Expr) {
    if (tokens.matchAny(&.{ .NOT, .minus })) |t| {
        const operand = switch (try parseUnary(tokens, pool)) {
            .ok => |expr| expr,
            .err => |err| return .ERR(err),
        };
        const expr = try pool.create();
        const loc: Location = .merge(&.{ operand.loc, t.loc });
        expr.* = .initUnary(loc, .init(t, operand));
        return .OK(expr);
    }
    return try parseAccess(tokens, pool);
}

fn parseValue(tokens: *core.parsing.Tokenizer.TokenIterator, pool: *std.heap.MemoryPool(Expr)) !core.results.ParseResult(*Expr) {
    if (tokens.matchAny(&.{ .string, .literal, .number })) |t| {
        const expr = try pool.create();
        expr.* = .initLiteral(t.loc, .init(t));
        return .OK(expr);
    } else if (tokens.match(.left_paren)) {
        const left_paren = tokens.peek(0);
        const group = switch (try parse(tokens, pool)) {
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
        const expr = try pool.create();
        const loc: Location = .merge(&.{ left_paren.loc, right_paren.loc });
        expr.* = .initGrouping(loc, .init(group));
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
