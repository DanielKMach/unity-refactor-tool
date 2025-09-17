const std = @import("std");
const core = @import("core");

const Func = @This();
const Expr = core.Expr;
const Value = Expr.Value;

pub const BuiltinFn = fn (args: []const Value, env: Expr.EvalEnv) anyerror!Value;

ptr: *const BuiltinFn,

pub fn call(self: Func, args: []const Value, env: Expr.EvalEnv) anyerror!Value {
    return self.ptr(args, env);
}

pub fn new(func: anytype) Func {
    const T = @TypeOf(func);
    if (@typeInfo(T) != .pointer or @typeInfo(@typeInfo(T).pointer.child) != .@"fn") {
        @compileError("'func' must be a pointer to a function.");
    }
    const info = @typeInfo(@typeInfo(T).pointer.child).@"fn";
    if (info.return_type != anyerror!Value) {
        @compileError("'func' must return " ++ @typeName(anyerror!Value) ++ ".");
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
        pub fn wrap(args: []const Value, env: Expr.EvalEnv) anyerror!Value {
            if (args.len != params.len - 1) return env.err(.{ .invalid_argument_count = .{
                .mode = .exact,
                .expected = params.len - 1,
                .found = args.len,
                .location = undefined,
            } });
            var tuple: TupleFromParams(params) = undefined;
            inline for (0..params.len) |i| {
                tuple[i] = switch (@TypeOf(tuple[i])) {
                    f32 => args[i].number,
                    []const u8 => args[i].string,
                    Value.Object => args[i].object,
                    Value.Func => args[i].func,
                    Value => args[i],
                    Expr.EvalEnv => env,
                    else => @compileError("Unsupported parameter type: " ++ @typeName(@TypeOf(tuple[i])) ++ "."),
                };
            }

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
    pub fn min(x: f32, y: f32, _: Expr.EvalEnv) anyerror!Value {
        return .{ .number = @min(x, y) };
    }

    pub fn max(x: f32, y: f32, _: Expr.EvalEnv) anyerror!Value {
        return .{ .number = @max(x, y) };
    }

    pub fn floor(x: f32, _: Expr.EvalEnv) anyerror!Value {
        return .{ .number = std.math.floor(x) };
    }

    pub fn ceil(x: f32, _: Expr.EvalEnv) anyerror!Value {
        return .{ .number = std.math.ceil(x) };
    }

    pub fn sqrt(x: f32, env: Expr.EvalEnv) anyerror!Value {
        if (x < 0) {
            _ = env;
            @panic("sqrt of negative number");
        }
        return .{ .number = std.math.sqrt(x) };
    }
};
