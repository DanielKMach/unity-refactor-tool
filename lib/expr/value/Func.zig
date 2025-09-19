const std = @import("std");
const core = @import("core");

const Func = @This();
const Expr = core.Expr;
const Value = Expr.Value;

pub const BuiltinFn = fn (*Expr.Call, []const Value.Traceable, Expr.EvalEnv) Expr.eval.Error!Value;

ptr: *const BuiltinFn,

pub fn call(self: Func, call_expr: *Expr.Call, args: []const Value.Traceable, env: Expr.EvalEnv) Expr.eval.Error!Value {
    return self.ptr(call_expr, args, env);
}

pub fn new(func: anytype) Func {
    const T = @TypeOf(func);
    if (@typeInfo(T) != .pointer or @typeInfo(@typeInfo(T).pointer.child) != .@"fn") {
        @compileError("'func' must be a pointer to a function.");
    }
    const info = @typeInfo(@typeInfo(T).pointer.child).@"fn";
    if (info.return_type != Expr.eval.Error!Value) {
        @compileError("'func' must return " ++ @typeName(Expr.eval.Error!Value) ++ ".");
    }

    const params = info.params[0 .. info.params.len - 1];
    for (params) |param| {
        const valid = for (@typeInfo(Value).@"union".fields) |fld| {
            if (param.type == fld.type) break true;
        } else param.type == Value.Traceable;
        if (!valid) @compileError("All but last parameters of 'func' must be of type " ++ @typeName(Value.Traceable) ++ " or one of its variants. Found " ++ @typeName(param.type) ++ ".");
    }
    if (info.params[params.len].type != Expr.EvalEnv) {
        @compileError("The last parameter of 'func' must be of type " ++ @typeName(Expr.EvalEnv) ++ ". Found " ++ @typeName(params[params.len].type) ++ ".");
    }

    const Wrapper = struct {
        pub fn wrap(call_expr: *Expr.Call, args: []const Value.Traceable, env: Expr.EvalEnv) Expr.eval.Error!Value {
            const loc = @as(*Expr, @fieldParentPtr("call", call_expr)).loc();
            if (args.len != params.len) return env.err(.{ .invalid_argument_count = .{
                .mode = .exact,
                .expected = params.len,
                .found = args.len,
                .location = loc,
            } });
            var tuple: TupleFromParams(info.params) = undefined;
            inline for (params, 0..) |param, i| {
                const expected: ?Value.Type = inline for (@typeInfo(Value).@"union".fields) |fld| {
                    if (param.type == fld.type) break @field(Value.Type, fld.name);
                } else null;
                if (expected) |e| {
                    try Value.validate(args[i], &.{e}, env.diag);
                    tuple[i] = @field(args[i].value, @tagName(e));
                } else {
                    tuple[i] = args[i];
                }
            }
            tuple[params.len] = env;

            return @call(.auto, func, tuple);
        }
    };
    return .{ .ptr = Wrapper.wrap };
}

fn TupleFromParams(comptime params: []const std.builtin.Type.Fn.Param) type {
    var fields = [_]std.builtin.Type.StructField{undefined} ** params.len;
    for (params, 0..) |p, i| {
        const P = p.type orelse unreachable;
        fields[i] = .{
            .name = &.{i + 48}, // '0', '1', '2', ...
            .type = P,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(P),
        };
    }
    return @Type(.{ .@"struct" = .{
        .backing_integer = null,
        .decls = &.{},
        .fields = &fields,
        .is_tuple = true,
        .layout = .auto,
    } });
}

/// Built-in functions.
pub const builtin = struct {
    pub fn min(x: f32, y: f32, _: Expr.EvalEnv) Expr.eval.Error!Value {
        return .{ .number = @min(x, y) };
    }

    pub fn max(x: f32, y: f32, _: Expr.EvalEnv) Expr.eval.Error!Value {
        return .{ .number = @max(x, y) };
    }

    pub fn floor(x: f32, _: Expr.EvalEnv) Expr.eval.Error!Value {
        return .{ .number = @floor(x) };
    }

    pub fn ceil(x: f32, _: Expr.EvalEnv) Expr.eval.Error!Value {
        return .{ .number = @ceil(x) };
    }

    pub fn trunc(x: f32, _: Expr.EvalEnv) Expr.eval.Error!Value {
        return .{ .number = @trunc(x) };
    }

    pub fn round(x: f32, _: Expr.EvalEnv) Expr.eval.Error!Value {
        return .{ .number = @round(x) };
    }

    pub fn sqrt(x: f32, _: Expr.EvalEnv) Expr.eval.Error!Value {
        if (x < 0) @panic("sqrt of negative number");
        return .{ .number = @sqrt(x) };
    }

    pub fn abs(x: f32, _: Expr.EvalEnv) Expr.eval.Error!Value {
        return .{ .number = @abs(x) };
    }

    pub fn cos(x: f32, _: Expr.EvalEnv) Expr.eval.Error!Value {
        return .{ .number = @cos(x) };
    }

    pub fn sin(x: f32, _: Expr.EvalEnv) Expr.eval.Error!Value {
        return .{ .number = @sin(x) };
    }

    pub fn prop(key: []const u8, env: Expr.EvalEnv) Expr.eval.Error!Value {
        return env.context.get(key) orelse .nil;
    }
};
