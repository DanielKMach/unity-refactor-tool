const std = @import("std");
const core = @import("core");

const Expr = core.Expr;
const Value = core.Expr.Value;
const Location = core.Token.Location;

pub const Error = core.RuntimeError || std.mem.Allocator.Error || error{LibyamlError};

pub fn evaluate(expr: *Expr, env: Expr.EvalEnv) Error!Value.Derived {
    return expr.derived(switch (expr.*) {
        .literal => |lit| switch (lit.token.value) {
            .number => |num| .{ .number = num },
            .string => |str| .{ .string = str },
            .NIL => .nil,
            else => unreachable,
        },
        .unary => |un| switch (un.op.value) {
            .minus => try negate(un.operand, env),
            .NOT => try logicalNot(un.operand, env),
            else => unreachable,
        },
        .binary => |bin| switch (bin.op.value) {
            .plus => try addOrConcat(bin.left, bin.right, env),
            .minus => try subtract(bin.left, bin.right, env),
            .star => try multiply(bin.left, bin.right, env),
            .slash => try divide(bin.left, bin.right, env),
            .percentage => try mod(bin.left, bin.right, env),
            .equal_equal => try equals(bin.left, bin.right, env),
            .bang_equal => try notEquals(bin.left, bin.right, env),
            .greater => try greaterThan(bin.left, bin.right, env),
            .less => try lessThan(bin.left, bin.right, env),
            .greater_equal => try greaterThanOrEqual(bin.left, bin.right, env),
            .less_equal => try lessThanOrEqual(bin.left, bin.right, env),
            .OR => try logicalOr(bin.left, bin.right, env),
            .AND => try logicalAnd(bin.left, bin.right, env),
            .question_question => try nullCoalesce(bin.left, bin.right, env),
            else => unreachable,
        },
        .ternary => |tern| try ternary(tern.left, tern.middle, tern.right, env),
        .grouping => |group| (try evaluate(group.expr, env)).val,
        .property => |prop| env.context.get(prop.name.value.literal) orelse .nil,
        .variable => |varr| env.vars.get(varr.name.value.variable) catch return env.err(.{
            .undefined_variable = .{ .varr = varr.name, .location = varr.name.loc },
        }),
        .access => |acc| try access(acc.base, acc.property.value.literal, env),
        .assignment => |as| switch (as.op.value) {
            .equal => try assign(as.target, as.value, env),
            .colon_equal => try define(as.target, as.value, env),
            else => unreachable,
        },
        .call => |*c| try call(c, env),
    });
}

pub fn addOrConcat(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    try Value.validate(a, &.{ .string, .number }, env.diag);
    const b = try evaluate(right, env);
    try Value.validate(b, &.{ .string, .number }, env.diag);
    if (a.val == .string or b.val == .string) {
        return .{ .string = try std.fmt.allocPrint(env.allocator, "{f}{f}", .{
            std.fmt.alt(a.val, .stringify),
            std.fmt.alt(b.val, .stringify),
        }) };
    } else if (a.val == .number and b.val == .number) {
        return .{ .number = a.val.number + b.val.number };
    }
    return env.err(.{ .type_mismatch = .{
        .left = a.val,
        .left_loc = left.loc(),
        .right = b.val,
        .right_loc = right.loc(),
    } });
}

pub fn subtract(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    try Value.validate(a, &.{.number}, env.diag);
    const b = try evaluate(right, env);
    try Value.validate(b, &.{.number}, env.diag);
    return .{ .number = a.val.number - b.val.number };
}

pub fn multiply(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    try Value.validate(a, &.{.number}, env.diag);
    const b = try evaluate(right, env);
    try Value.validate(b, &.{.number}, env.diag);
    return .{ .number = a.val.number * b.val.number };
}

pub fn divide(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    try Value.validate(a, &.{.number}, env.diag);
    const b = try evaluate(right, env);
    try Value.validate(b, &.{.number}, env.diag);

    if (b.val.number == 0) return env.err(.{ .division_by_zero = .{
        .location = .merge(&.{ left.loc(), right.loc() }),
    } });
    return .{ .number = a.val.number / b.val.number };
}

pub fn mod(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    try Value.validate(a, &.{.number}, env.diag);
    const b = try evaluate(right, env);
    try Value.validate(b, &.{.number}, env.diag);

    if (b.val.number == 0) return env.err(.{ .division_by_zero = .{
        .location = .merge(&.{ left.loc(), right.loc() }),
    } });
    return .{ .number = @mod(a.val.number, b.val.number) };
}

pub fn negate(expr: *Expr, env: Expr.EvalEnv) Error!Value {
    const x = try evaluate(expr, env);
    try Value.validate(x, &.{.number}, env.diag);
    return .{ .number = -x.val.number };
}

pub fn equals(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = (try evaluate(left, env)).val;
    const b = (try evaluate(right, env)).val;
    return .{ .number = if (Value.eql(a, b)) 1 else 0 };
}

pub fn notEquals(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = (try evaluate(left, env)).val;
    const b = (try evaluate(right, env)).val;
    return .{ .number = if (!Value.eql(a, b)) 1 else 0 };
}

pub fn lessThan(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    try Value.validate(a, &.{.number}, env.diag);
    const b = try evaluate(right, env);
    try Value.validate(b, &.{.number}, env.diag);
    return .{ .number = if (a.val.number < b.val.number) 1 else 0 };
}

pub fn greaterThan(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    try Value.validate(a, &.{.number}, env.diag);
    const b = try evaluate(right, env);
    try Value.validate(b, &.{.number}, env.diag);
    return .{ .number = if (a.val.number > b.val.number) 1 else 0 };
}

pub fn lessThanOrEqual(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    try Value.validate(a, &.{.number}, env.diag);
    const b = try evaluate(right, env);
    try Value.validate(b, &.{.number}, env.diag);
    return .{ .number = if (a.val.number <= b.val.number) 1 else 0 };
}

pub fn greaterThanOrEqual(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    try Value.validate(a, &.{.number}, env.diag);
    const b = try evaluate(right, env);
    try Value.validate(b, &.{.number}, env.diag);
    return .{ .number = if (a.val.number >= b.val.number) 1 else 0 };
}

pub fn logicalAnd(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    if (!a.val.isTruthy()) return .{ .number = 0 };
    const b = try evaluate(right, env);
    if (!b.val.isTruthy()) return .{ .number = 0 };
    return .{ .number = 1 };
}

pub fn logicalOr(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    if (a.val.isTruthy()) return .{ .number = 1 };
    const b = try evaluate(right, env);
    if (b.val.isTruthy()) return .{ .number = 1 };
    return .{ .number = 0 };
}

pub fn logicalNot(expr: *Expr, env: Expr.EvalEnv) Error!Value {
    const res = try evaluate(expr, env);
    if (res.val.isTruthy()) return .{ .number = 0 };
    return .{ .number = 1 };
}

pub fn nullCoalesce(left: *Expr, right: *Expr, env: Expr.EvalEnv) Error!Value {
    const a = try evaluate(left, env);
    if (a.val != .nil) return a.val;

    const b = try evaluate(right, env);
    return b.val;
}

pub fn ternary(condition: *Expr, then: *Expr, otherwise: *Expr, env: Expr.EvalEnv) Error!Value {
    const cond = try evaluate(condition, env);

    const target = if (cond.val.isTruthy()) then else otherwise;
    return (try evaluate(target, env)).val;
}

pub fn access(base: *Expr, key: []const u8, env: Expr.EvalEnv) Error!Value {
    const obj = try evaluate(base, env);
    try Value.validate(obj, &.{.object}, env.diag);

    return obj.val.object.get(key) orelse .nil;
}

pub fn define(target: *Expr, init: *Expr, env: Expr.EvalEnv) Error!Value {
    return switch (target.*) {
        .variable => |varr| blk: {
            const key = varr.name.value.variable;
            const val = (try evaluate(init, env)).val;
            env.vars.define(key, val) catch |err| return switch (err) {
                error.ReadOnly => env.err(.{ .overriding_readonly = .{
                    .varr = varr.name,
                    .location = .merge(&.{ target.loc(), init.loc() }),
                } }),
                error.AlreadyDefined => env.err(.{ .already_defined_variable = .{
                    .varr = varr.name,
                    .location = .merge(&.{ target.loc(), init.loc() }),
                } }),
                else => |e| e,
            };
            break :blk val;
        },
        else => try assign(target, init, env),
    };
}

pub fn assign(target: *Expr, value: *Expr, env: Expr.EvalEnv) Error!Value {
    const val = (try evaluate(value, env)).val;
    switch (target.*) {
        .access => |acc| {
            const key = acc.property.value.literal;
            const obj = try evaluate(acc.base, env);
            try Value.validate(obj, &.{.object}, env.diag);
            try obj.val.object.set(key, val);
        },
        .property => |prop| {
            const key = prop.name.value.literal;
            try env.context.set(key, val);
        },
        .variable => |varr| {
            const key = varr.name.value.variable;
            env.vars.set(key, val) catch |err| return switch (err) {
                error.ReadOnly => env.err(.{ .overriding_readonly = .{
                    .varr = varr.name,
                    .location = .merge(&.{ target.loc(), value.loc() }),
                } }),
                error.UndefinedVariable => env.err(.{ .undefined_variable = .{
                    .varr = varr.name,
                    .location = .merge(&.{ target.loc(), value.loc() }),
                } }),
                else => |e| e,
            };
        },
        // .indexing => {} TODO
        else => unreachable,
    }
    return val;
}

pub fn call(call_expr: *Expr.Call, env: Expr.EvalEnv) Error!Value {
    const callee = try evaluate(call_expr.callee, env);
    try Value.validate(callee, &.{.func}, env.diag);
    const vargs = try env.allocator.alloc(Value.Derived, call_expr.args.len);
    for (call_expr.args, vargs) |arg, *varg| {
        varg.* = try evaluate(arg, env);
    }
    return try callee.val.func.call(call_expr, vargs, env);
}
