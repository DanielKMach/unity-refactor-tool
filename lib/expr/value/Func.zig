const std = @import("std");
const core = @import("core");

const Func = @This();
const Expr = core.Expr;
const Value = Expr.Value;

pub const BuiltinFn = fn (call_expr: *Expr.Call, env: Expr.EvalEnv) Expr.eval.Error!Value;

ptr: *const BuiltinFn,

pub fn call(self: Func, call_expr: *Expr.Call, env: Expr.EvalEnv) Expr.eval.Error!Value {
    return self.ptr(call_expr, env);
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

    const params = info.params;
    for (params[0 .. params.len - 1]) |param| {
        const valid = for (@typeInfo(Value).@"union".fields) |fld| {
            if (param.type == fld.type) break true;
        } else param.type == Value;
        if (!valid) @compileError("All but last parameters of 'func' must be of type " ++ @typeName(Value) ++ " or one of its variants. Found " ++ @typeName(param.type) ++ ".");
    }
    if (params[params.len - 1].type != Expr.EvalEnv) {
        @compileError("The last parameter of 'func' must be of type " ++ @typeName(Expr.EvalEnv) ++ ". Found " ++ @typeName(params[params.len - 1].type) ++ ".");
    }

    const Wrapper = struct {
        pub fn wrap(call_expr: *Expr.Call, env: Expr.EvalEnv) Expr.eval.Error!Value {
            const expr: *Expr = @fieldParentPtr("call", call_expr);
            if (call_expr.args.len != params.len - 1) return env.err(.{ .invalid_argument_count = .{
                .mode = .exact,
                .expected = params.len - 1,
                .found = call_expr.args.len,
                .location = expr.loc(),
            } });
            var tuple: TupleFromParams(params) = undefined;
            inline for (0..params.len - 1) |i| {
                const expected: ?Value.Type = switch (@TypeOf(tuple[i])) {
                    f32 => .number,
                    []const u8 => .string,
                    Value.Object => .object,
                    Value.Func => .func,
                    Value => null,
                    else => @compileError("Unsupported parameter type: " ++ @typeName(@TypeOf(tuple[i])) ++ "."),
                };
                if (expected) |e| {
                    const value = try Expr.eval.validate(call_expr.args[i], &.{e}, env);
                    tuple[i] = @field(value, @tagName(e));
                } else {
                    tuple[i] = try Expr.eval.evaluate(call_expr.args[i], env);
                }
            }
            tuple[params.len - 1] = env;

            return @call(.auto, func, tuple);
        }
    };
    return .{
        .ptr = Wrapper.wrap,
    };
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
