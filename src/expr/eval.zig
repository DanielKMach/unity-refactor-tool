const std = @import("std");
const core = @import("core");

const Expr = core.Expr;
const Value = core.Expr.Value;
const Location = core.Token.Location;
const RuntimeResult = core.results.RuntimeResult;
const RuntimeError = core.results.RuntimeError;

pub fn evaluate(expr: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    return switch (expr.*) {
        .literal => |lit| .OK(switch (lit.token.value) {
            .number => |num| .{ .number = num },
            .string => |str| .{ .string = str },
            else => unreachable,
        }),
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
        .variable => |varr| .OK(env.context.get(varr.name.value.literal) orelse .nil),
        .access => |acc| access(acc.base, acc.property.value.literal, env),
        .assignment => |as| assign(as.target, as.value, env),
    };
}

pub fn addOrConcat(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{ .string, .number }, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try validateType(right, &.{ .string, .number }, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    return .OK(switch (a) {
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
    });
}

pub fn add(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    return .OK(.{ .number = a.number + b.number });
}

pub fn subtract(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    return .OK(.{ .number = a.number - b.number });
}

pub fn multiply(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    return .OK(.{ .number = a.number * b.number });
}

pub fn divide(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    if (b.number == 0) return .ERR(.{
        .division_by_zero = .{ .location = Location.merge(&.{ left.loc(), right.loc() }) },
    });
    return .OK(.{ .number = a.number / b.number });
}

pub fn mod(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    if (b.number == 0) return .ERR(.{
        .division_by_zero = .{ .location = Location.merge(&.{ left.loc(), right.loc() }) },
    });
    return .OK(.{ .number = @mod(a.number, b.number) });
}

pub fn negate(expr: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const res = try validateType(expr, &.{.number}, env);
    const value = res.isOk() orelse return .ERR(res.err);
    return .OK(.{ .number = -value.number });
}

pub fn equals(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try evaluate(left, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try evaluate(right, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    if (@as(Value.Type, a) != @as(Value.Type, b)) {
        return .OK(.{ .number = 0 });
    }

    return switch (a) {
        .number => |a_number| .OK(.{ .number = if (a_number == b.number) 1 else 0 }),
        .string => |a_string| .OK(.{ .number = if (std.mem.eql(u8, a_string, b.string)) 1 else 0 }),
        .nil => .OK(.{ .number = 1 }),
        .object => |a_object| .OK(.{ .number = if (a_object.node == b.object.node) 1 else 0 }),
        .array => @panic("TODO: Handle array"),
    };
}

pub fn notEquals(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try evaluate(left, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try evaluate(right, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    if (@as(Value.Type, a) != @as(Value.Type, b)) {
        return .OK(.{ .number = 1 });
    }
    return switch (a) {
        .number => |a_number| .OK(.{ .number = if (a_number != b.number) 1 else 0 }),
        .string => |a_string| .OK(.{ .number = if (!std.mem.eql(u8, a_string, b.string)) 1 else 0 }),
        .nil => .OK(.{ .number = 0 }),
        .object => |a_object| .OK(.{ .number = if (a_object.node != b.object.node) 1 else 0 }),
        .array => @panic("TODO: Handle array"),
    };
}

pub fn lessThan(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    return .OK(.{ .number = if (a.number < b.number) 1 else 0 });
}

pub fn greaterThan(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    return .OK(.{ .number = if (a.number > b.number) 1 else 0 });
}

pub fn lessThanOrEqual(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    return .OK(.{ .number = if (a.number <= b.number) 1 else 0 });
}

pub fn greaterThanOrEqual(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.number}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try validateType(right, &.{.number}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    return .OK(.{ .number = if (a.number >= b.number) 1 else 0 });
}

pub fn logicalAnd(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try evaluate(left, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try evaluate(right, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    return .OK(.{ .number = if (isTrythy(a) and isTrythy(b)) 1 else 0 });
}

pub fn logicalOr(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try evaluate(left, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try evaluate(right, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    return .OK(.{ .number = if (isTrythy(a) or isTrythy(b)) 1 else 0 });
}

pub fn logicalNot(expr: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const res = try evaluate(expr, env);
    const value = res.isOk() orelse return .ERR(res.err);
    defer value.cleanup(env.allocator);
    return .OK(.{ .number = if (isTrythy(value)) 0 else 1 });
}

pub fn nullCoalesce(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try evaluate(left, env);
    const a = resA.isOk() orelse return .ERR(resA.err);
    if (a != .nil) return .OK(a);

    const resB = try evaluate(right, env);
    const b = resB.isOk() orelse return .ERR(resB.err);
    return .OK(b);
}

pub fn concat(left: *Expr, right: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const resA = try validateType(left, &.{.string}, env);
    const a = resA.isOk() orelse return .ERR(resA.err);

    const resB = try validateType(right, &.{.string}, env);
    const b = resB.isOk() orelse return .ERR(resB.err);

    const combined = try env.allocator.alloc(u8, a.string.len + b.string.len);
    @memcpy(combined[0..a.string.len], a.string);
    @memcpy(combined[a.string.len..], b.string);

    return .OK(.{ .string = combined });
}

pub fn ternary(condition: *Expr, then: *Expr, otherwise: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const cond_res = try evaluate(condition, env);
    const cond_value = cond_res.isOk() orelse return .ERR(cond_res.err);

    const target = if (isTrythy(cond_value)) then else otherwise;
    return evaluate(target, env);
}

pub fn access(base: *Expr, key: []const u8, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const obj_res = try validateType(base, &.{.object}, env);
    const obj = obj_res.isOk() orelse return .ERR(obj_res.err);

    return .OK(obj.object.get(key) orelse .nil);
}

pub fn assign(access_expr: *Expr, value: *Expr, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const result = try evaluate(value, env);
    const val = result.isOk() orelse return .ERR(result.err);

    switch (access_expr.*) {
        .access => |acc| {
            const key = acc.property.value.literal;

            const obj_res = try validateType(acc.base, &.{.object}, env);
            const obj = obj_res.isOk() orelse return .ERR(obj_res.err);

            try obj.object.set(key, val);
        },
        .variable => |varr| {
            const key = varr.name.value.literal;
            if (env.vars.has(key)) {
                try env.vars.set(key, val);
            } else {
                try env.context.set(key, val);
            }
        },
        // .indexing => {} TODO
        else => unreachable,
    }

    return .OK(val);
}

fn isTrythy(value: Value) bool {
    return switch (value) {
        .number => |num| num != 0,
        .string => |str| str.len > 0,
        .nil => false,
        .object => true, // should objects always eval to true?
        .array => @panic("TODO: Handle array"),
    };
}

fn validateType(expr: *Expr, comptime types: []const Value.Type, env: Expr.RunEnv) anyerror!RuntimeResult(Value) {
    const result = try evaluate(expr, env);
    const value = result.isOk() orelse return .ERR(result.err);
    inline for (types) |t| {
        if (value == t) return .OK(value);
    }
    return .ERR(.{
        .unexpected_type = .{
            .found = value,
            .location = expr.loc(),
            .expected = types,
        },
    });
}
