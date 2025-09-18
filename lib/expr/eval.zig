const std = @import("std");
const core = @import("core");

const Expr = core.Expr;
const Value = core.Expr.Value;
const Location = core.Token.Location;

pub const Error = core.RuntimeError || std.mem.Allocator.Error || error{LibyamlError};

pub fn evaluate(expr: *Expr, env: Expr.EvalEnv) Error!Value {
    return switch (expr.*) {
        .literal => |lit| switch (lit.token.value) {
            .number => |num| .{ .number = num },
            .string => |str| .{ .string = str },
            else => unreachable,
        },
        .unary => |un| switch (un.op.value) {
            .minus => negate(un.operand, env),
            .NOT => logicalNot(un.operand, env),
            else => unreachable,
        },
        .binary => |bin| switch (bin.op.value) {
            .plus => addOrConcat(bin.left, bin.right, env),
            .minus => subtract(bin.left, bin.right, env),
            .star => multiply(bin.left, bin.right, env),
            .slash => divide(bin.left, bin.right, env),
            .percentage => mod(bin.left, bin.right, env),
            .equal_equal => equals(bin.left, bin.right, env),
            .bang_equal => notEquals(bin.left, bin.right, env),
            .greater => greaterThan(bin.left, bin.right, env),
            .less => lessThan(bin.left, bin.right, env),
            .greater_equal => greaterThanOrEqual(bin.left, bin.right, env),
            .less_equal => lessThanOrEqual(bin.left, bin.right, env),
            .OR => logicalOr(bin.left, bin.right, env),
            .AND => logicalAnd(bin.left, bin.right, env),
            .question_question => nullCoalesce(bin.left, bin.right, env),
            else => unreachable,
        },
        .ternary => |tern| ternary(tern.left, tern.middle, tern.right, env),
        .grouping => |group| evaluate(group.expr, env),
        .property => |prop| env.context.get(prop.name.value.literal) orelse .nil,
        .variable => |varr| env.vars.get(varr.name.value.variable) catch @panic("TODO: Handle undefined variable"),
        .access => |acc| access(acc.base, acc.property.value.literal, env),
        .assignment => |as| switch (as.op.value) {
            .equal => assign(as.target, as.value, env),
            .colon_equal => define(as.target, as.value, env),
            else => unreachable,
        },
        .call => |*c| call(c, env),
    };
}

pub fn addOrConcat(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try validate(left, &.{ .string, .number }, env);

    const b = try validate(right, &.{ .string, .number }, env);

    return switch (a) {
        .string => |str_a| switch (b) {
            .string => |str_b| .{ .string = try std.fmt.allocPrint(env.allocator, "{s}{s}", .{ str_a, str_b }) },
            .number => |num_b| .{ .string = try std.fmt.allocPrint(env.allocator, "{s}{d}", .{ str_a, num_b }) },
            else => unreachable,
        },
        .number => |num_a| switch (b) {
            .string => |str_b| .{ .string = try std.fmt.allocPrint(env.allocator, "{d}{s}", .{ num_a, str_b }) },
            .number => |num_b| .{ .number = num_a + num_b },
            else => unreachable,
        },
        else => unreachable,
    };
}

pub fn add(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try validate(left, &.{.number}, env);

    const b = try validate(right, &.{.number}, env);

    return .{ .number = a.number + b.number };
}

pub fn subtract(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try validate(left, &.{.number}, env);

    const b = try validate(right, &.{.number}, env);

    return .{ .number = a.number - b.number };
}

pub fn multiply(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try validate(left, &.{.number}, env);

    const b = try validate(right, &.{.number}, env);

    return .{ .number = a.number * b.number };
}

pub fn divide(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try validate(left, &.{.number}, env);

    const b = try validate(right, &.{.number}, env);

    if (b.number == 0) return env.err(.{ .division_by_zero = .{
        .location = Location.merge(&.{ left.loc(), right.loc() }),
    } });
    return .{ .number = a.number / b.number };
}

pub fn mod(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try validate(left, &.{.number}, env);

    const b = try validate(right, &.{.number}, env);

    if (b.number == 0) return env.err(.{ .division_by_zero = .{
        .location = Location.merge(&.{ left.loc(), right.loc() }),
    } });
    return .{ .number = @mod(a.number, b.number) };
}

pub fn negate(expr: *Expr, env: Expr.EvalEnv) Error!Value {
    const value = try validate(expr, &.{.number}, env);
    return .{ .number = -value.number };
}

pub fn equals(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    const b = try evaluate(right, env);
    if (@as(Value.Type, a) != @as(Value.Type, b)) {
        return .{ .number = 0 };
    }

    return switch (a) {
        .number => |a_number| .{ .number = if (a_number == b.number) 1 else 0 },
        .string => |a_string| .{ .number = if (std.mem.eql(u8, a_string, b.string)) 1 else 0 },
        .nil => .{ .number = 1 },
        .object => |a_object| .{ .number = if (a_object.node == b.object.node) 1 else 0 },
        .array => @panic("TODO: Handle array"),
        .func => |a_func| .{ .number = if (a_func.ptr == b.func.ptr) 1 else 0 },
    };
}

pub fn notEquals(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const eqls = try equals(left, right, env);
    return .{ .number = if (eqls.number == 0) 1 else 0 };
}

pub fn lessThan(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try validate(left, &.{.number}, env);

    const b = try validate(right, &.{.number}, env);

    return .{ .number = if (a.number < b.number) 1 else 0 };
}

pub fn greaterThan(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try validate(left, &.{.number}, env);

    const b = try validate(right, &.{.number}, env);

    return .{ .number = if (a.number > b.number) 1 else 0 };
}

pub fn lessThanOrEqual(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try validate(left, &.{.number}, env);

    const b = try validate(right, &.{.number}, env);

    return .{ .number = if (a.number <= b.number) 1 else 0 };
}

pub fn greaterThanOrEqual(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try validate(left, &.{.number}, env);

    const b = try validate(right, &.{.number}, env);

    return .{ .number = if (a.number >= b.number) 1 else 0 };
}

pub fn logicalAnd(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    const b = try evaluate(right, env);
    return .{ .number = if (isTrythy(a) and isTrythy(b)) 1 else 0 };
}

pub fn logicalOr(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    const b = try evaluate(right, env);
    return .{ .number = if (isTrythy(a) or isTrythy(b)) 1 else 0 };
}

pub fn logicalNot(expr: *Expr, env: Expr.EvalEnv) Error!Value {
    const value = try evaluate(expr, env);
    return .{ .number = if (isTrythy(value)) 0 else 1 };
}

pub fn nullCoalesce(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    if (a != .nil) return a;

    const b = try evaluate(right, env);
    return b;
}

pub fn concat(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try validate(left, &.{.string}, env);
    const b = try validate(right, &.{.string}, env);

    const combined = try env.allocator.alloc(u8, a.string.len + b.string.len);
    @memcpy(combined[0..a.string.len], a.string);
    @memcpy(combined[a.string.len..], b.string);

    return .{ .string = combined };
}

pub fn ternary(condition: *Expr, then: *Expr, otherwise: *Expr, env: Expr.EvalEnv) Error!Value {
    const cond = try evaluate(condition, env);

    const target = if (isTrythy(cond)) then else otherwise;
    return evaluate(target, env);
}

pub fn access(base: *Expr, key: []const u8, env: Expr.EvalEnv) Error!Value {
    const obj = try validate(base, &.{.object}, env);

    return obj.object.get(key) orelse .nil;
}

pub fn define(target: *Expr, init: *Expr, env: Expr.EvalEnv) Error!Value {
    return switch (target.*) {
        .variable => |varr| blk: {
            const key = varr.name.value.variable;
            const val = try evaluate(init, env);
            env.vars.define(key, val) catch |err| switch (err) {
                error.ReadOnly => @panic("TODO: Handle read-only variable"),
                error.AlreadyDefined => @panic("TODO: Handle already defined variable"),
                else => |e| return e,
            };
            break :blk val;
        },
        else => try assign(target, init, env),
    };
}

pub fn assign(target: *Expr, value: *Expr, env: Expr.EvalEnv) Error!Value {
    const val = try evaluate(value, env);
    switch (target.*) {
        .access => |acc| {
            const key = acc.property.value.literal;
            const obj = try validate(acc.base, &.{.object}, env);
            try obj.object.set(key, val);
        },
        .property => |prop| {
            const key = prop.name.value.literal;
            try env.context.set(key, val);
        },
        .variable => |varr| {
            const key = varr.name.value.variable;
            env.vars.set(key, val) catch |err| switch (err) {
                error.ReadOnly => @panic("TODO: Handle read-only variable"),
                error.UndefinedVariable => @panic("TODO: Handle undefined variable"),
                else => |e| return e,
            };
        },
        // .indexing => {} TODO
        else => unreachable,
    }

    return val;
}

pub fn call(call_expr: *Expr.Call, env: Expr.EvalEnv) Error!Value {
    const callee = try validate(call_expr.callee, &.{.func}, env);
    return try callee.func.call(call_expr, env);
}

fn isTrythy(value: Value) bool {
    return switch (value) {
        .number => |num| num != 0,
        .string => |str| str.len > 0,
        .nil => false,
        .object => true, // should objects always eval to true?
        .array => @panic("TODO: Handle array"),
        .func => true, // functions should always eval to true?
    };
}

pub fn validate(expr: *Expr, types: []const Value.Type, env: Expr.EvalEnv) Error!Value {
    const value = try evaluate(expr, env);
    for (types) |t| {
        if (value == t) return value;
    }
    return env.err(.{
        .unexpected_type = .{
            .found = value,
            .location = expr.loc(),
            .expected = types,
        },
    });
}
