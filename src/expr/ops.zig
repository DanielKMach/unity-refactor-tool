const std = @import("std");
const core = @import("core");

const Expr = core.Expr;
const Value = core.Expr.Value;
const Location = core.Token.Location;
const RuntimeResult = core.results.RuntimeResult;
const RuntimeError = core.results.RuntimeError;

pub fn add(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    defer a.cleanup(env.allocator);
    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    defer b.cleanup(env.allocator);
    return .OK(.{ .number = a.number + b.number });
}

pub fn subtract(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    defer a.cleanup(env.allocator);
    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    defer b.cleanup(env.allocator);
    return .OK(.{ .number = a.number - b.number });
}

pub fn multiply(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    defer a.cleanup(env.allocator);
    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    defer b.cleanup(env.allocator);
    return .OK(.{ .number = a.number * b.number });
}

pub fn divide(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    defer a.cleanup(env.allocator);
    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    defer b.cleanup(env.allocator);
    if (b.number == 0) return .ERR(.{
        .division_by_zero = .{ .location = right.loc },
    });
    return .OK(.{ .number = a.number / b.number });
}

pub fn negate(expr: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const res = try validateType(expr, &.{.number}, env);
    const value = res.isOk() orelse return .ERR(res.err);
    defer value.cleanup(env.allocator);
    return .OK(.{ .number = -value.number });
}

pub fn equals(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try left.evaluate(env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    defer a.cleanup(env.allocator);
    const resB = try right.evaluate(env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    defer b.cleanup(env.allocator);
    if (@as(Value.Type, a) != @as(Value.Type, b)) {
        return .OK(.{ .number = 0 });
    }

    return switch (a) {
        .number => |a_number| .OK(.{ .number = if (a_number == b.number) 1 else 0 }),
        .string => |a_string| .OK(.{ .number = if (std.mem.eql(u8, a_string, b.string)) 1 else 0 }),
        .nil => .OK(.{ .number = 1 }),
        else => unreachable, // TODO: Handle object and array
    };
}

pub fn notEquals(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try left.evaluate(env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    defer a.cleanup(env.allocator);
    const resB = try right.evaluate(env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    defer b.cleanup(env.allocator);
    if (@as(Value.Type, a) != @as(Value.Type, b)) {
        return .OK(.{ .number = 1 });
    }
    return switch (a) {
        .number => |a_number| .OK(.{ .number = if (a_number != b.number) 1 else 0 }),
        .string => |a_string| .OK(.{ .number = if (!std.mem.eql(u8, a_string, b.string)) 1 else 0 }),
        .nil => .OK(.{ .number = 0 }),
        else => unreachable, // TODO: Handle object and array
    };
}

pub fn lessThan(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    defer a.cleanup(env.allocator);
    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    defer b.cleanup(env.allocator);
    return .OK(.{ .number = if (a.number < b.number) 1 else 0 });
}

pub fn greaterThan(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    defer a.cleanup(env.allocator);
    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    defer b.cleanup(env.allocator);
    return .OK(.{ .number = if (a.number > b.number) 1 else 0 });
}

pub fn lessThanOrEqual(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    defer a.cleanup(env.allocator);
    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    defer b.cleanup(env.allocator);
    return .OK(.{ .number = if (a.number <= b.number) 1 else 0 });
}

pub fn greaterThanOrEqual(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    defer a.cleanup(env.allocator);
    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    defer b.cleanup(env.allocator);
    return .OK(.{ .number = if (a.number >= b.number) 1 else 0 });
}

pub fn logicalAnd(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try left.evaluate(env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    defer a.cleanup(env.allocator);
    const resB = try right.evaluate(env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    defer b.cleanup(env.allocator);
    return .OK(.{ .number = if (isTrythy(a) and isTrythy(b)) 1 else 0 });
}

pub fn logicalOr(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try left.evaluate(env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    defer a.cleanup(env.allocator);
    const resB = try right.evaluate(env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    defer b.cleanup(env.allocator);
    return .OK(.{ .number = if (isTrythy(a) or isTrythy(b)) 1 else 0 });
}

pub fn logicalNot(expr: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const res = try expr.evaluate(env);
    const value = res.isOk() orelse return .ERR(res.err);
    defer value.cleanup(env.allocator);
    return .OK(.{ .number = if (isTrythy(value)) 0 else 1 });
}

pub fn concat(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.string}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    defer a.cleanup(env.allocator);
    const resB = try validateType(right, &.{.string}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    defer b.cleanup(env.allocator);

    const combined = try env.allocator.alloc(u8, a.string.len + b.string.len);
    @memcpy(combined[0..a.string.len], a.string);
    @memcpy(combined[a.string.len..], b.string);

    return .OK(.{ .string = combined });
}

fn isTrythy(value: Value) bool {
    return switch (value) {
        .number => |num| num != 0,
        .string => |str| str.len > 0,
        .nil => false,
        else => unreachable, // TODO: Handle object and array
    };
}

fn validateType(expr: *Expr, comptime types: []const Value.Type, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const result = try expr.evaluate(env);
    const value = result.isOk() orelse return .ERR(result.err);
    inline for (types) |t| {
        if (value == t) return .OK(value);
    }
    value.cleanup(env.allocator);
    return .ERR(.{
        .unexpected_type = .{
            .found = value,
            .location = expr.loc,
            .expected = types,
        },
    });
}
