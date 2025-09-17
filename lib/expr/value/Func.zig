const std = @import("std");
const core = @import("core");

const Func = @This();
const Expr = core.Expr;
const Value = Expr.Value;

pub const min = Func{ .ptr = builtin.min };
pub const max = Func{ .ptr = builtin.max };
pub const floor = Func{ .ptr = builtin.floor };
pub const ceil = Func{ .ptr = builtin.ceil };
pub const sqrt = Func{ .ptr = builtin.sqrt };

pub const BuiltinFn = fn (args: []const Value, env: Expr.EvalEnv) anyerror!Value;

ptr: *const BuiltinFn,

pub fn call(self: Func, args: []const Value, env: Expr.EvalEnv) anyerror!Value {
    return self.ptr(args, env);
}

/// Built-in functions.
pub const builtin = struct {
    comptime {
        for (std.meta.declarations(builtin)) |decl| {
            const d = @field(builtin, decl.name);
            if (@typeInfo(@TypeOf(d)) == .@"fn" and @TypeOf(d) != BuiltinFn) {
                @compileError(decl.name ++ " doesn't match the signature: " ++ @typeName(BuiltinFn));
            }
        }
    }

    pub fn min(args: []const Value, env: Expr.EvalEnv) anyerror!Value {
        if (args.len == 0) {
            return env.err(.{ .invalid_argument_count = .{
                .mode = .at_least,
                .expected = 1,
                .found = 0,
                .location = .{ .index = 0, .len = 0 },
            } });
        }
        var min_value = std.math.floatMax(f32);
        for (args) |arg| {
            if (arg != .number) {
                return env.err(.{ .unexpected_type = .{
                    .expected = &.{.number},
                    .found = arg,
                    .location = .{ .index = 0, .len = 0 },
                } });
            }
            if (arg.number < min_value) {
                min_value = arg.number;
            }
        }
        return .{ .number = min_value };
    }

    pub fn max(args: []const Value, env: Expr.EvalEnv) anyerror!Value {
        if (args.len == 0) {
            return env.err(.{ .invalid_argument_count = .{
                .mode = .at_least,
                .expected = 1,
                .found = 0,
                .location = .{ .index = 0, .len = 0 },
            } });
        }
        var max_value = std.math.floatMin(f32);
        for (args) |arg| {
            if (arg != .number) {
                return env.err(.{ .unexpected_type = .{
                    .expected = &.{.number},
                    .found = arg,
                    .location = .{ .index = 0, .len = 0 },
                } });
            }
            if (arg.number > max_value) {
                max_value = arg.number;
            }
        }
        return .{ .number = max_value };
    }

    pub fn floor(args: []const Value, env: Expr.EvalEnv) anyerror!Value {
        if (args.len != 1) {
            return env.err(.{ .invalid_argument_count = .{
                .mode = .exact,
                .expected = 1,
                .found = args.len,
                .location = .{ .index = 0, .len = args.len },
            } });
        }
        if (args[0] != .number) {
            return env.err(.{ .unexpected_type = .{
                .expected = &.{.number},
                .found = args[0],
                .location = .{ .index = 0, .len = args.len },
            } });
        }
        return .{ .number = std.math.floor(args[0].number) };
    }

    pub fn ceil(args: []const Value, env: Expr.EvalEnv) anyerror!Value {
        if (args.len != 1) {
            return env.err(.{ .invalid_argument_count = .{
                .mode = .exact,
                .expected = 1,
                .found = args.len,
                .location = .{ .index = 0, .len = args.len },
            } });
        }
        if (args[0] != .number) {
            return env.err(.{ .unexpected_type = .{
                .expected = &.{.number},
                .found = args[0],
                .location = .{ .index = 0, .len = args.len },
            } });
        }
        return .{ .number = std.math.ceil(args[0].number) };
    }

    pub fn sqrt(args: []const Value, env: Expr.EvalEnv) anyerror!Value {
        if (args.len != 1) {
            return env.err(.{ .invalid_argument_count = .{
                .mode = .exact,
                .expected = 1,
                .found = args.len,
                .location = .{ .index = 0, .len = args.len },
            } });
        }
        if (args[0] != .number) {
            return env.err(.{ .unexpected_type = .{
                .expected = &.{.number},
                .found = args[0],
                .location = .{ .index = 0, .len = args.len },
            } });
        }
        if (args[0].number < 0) {
            @panic("sqrt of negative number");
        }
        return .{ .number = std.math.sqrt(args[0].number) };
    }
};
