const std = @import("std");
const core = @import("core");

const Func = @This();
const Expr = core.Expr;
const Value = Expr.Value;

pub const min = Func{ .ptr = builtin.min };

pub const PtrFuncFn = fn (args: []const Value, env: Expr.EvalEnv) anyerror!Value;

ptr: *const PtrFuncFn,

pub fn call(self: Func, args: []const Value, env: Expr.EvalEnv) anyerror!Value {
    return self.ptr(args, env);
}

/// Built-in functions.
pub const builtin = struct {
    comptime {
        for (std.meta.declarations(builtin)) |decl| {
            const d = @field(builtin, decl.name);
            if (@typeInfo(@TypeOf(d)) == .@"fn" and @TypeOf(d) != PtrFuncFn) {
                @compileError("All functions in builtin must match the signature: " ++ @typeName(PtrFuncFn));
            }
        }
    }

    pub fn min(args: []const Value, env: core.Expr.EvalEnv) anyerror!Value {
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
};
