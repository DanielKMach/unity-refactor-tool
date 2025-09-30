const std = @import("std");
const core = @import("core");

const Func = @This();
const Expr = core.Expr;
const Value = Expr.Value;

pub const BuiltinFn = fn (*Expr.Call, []const Value.Derived, Expr.EvalEnv) Expr.eval.Error!Value;

ptr: *const BuiltinFn,

pub fn call(self: Func, call_expr: *Expr.Call, args: []const Value.Derived, env: Expr.EvalEnv) Expr.eval.Error!Value {
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
        } else param.type == Value.Derived;
        if (!valid) @compileError("All but last parameters of 'func' must be of type " ++ @typeName(Value.Derived) ++ " or one of its variants. Found " ++ @typeName(param.type) ++ ".");
    }
    if (info.params[params.len].type != Expr.EvalEnv) {
        @compileError("The last parameter of 'func' must be of type " ++ @typeName(Expr.EvalEnv) ++ ". Found " ++ @typeName(params[params.len].type) ++ ".");
    }

    const Wrapper = struct {
        pub fn wrap(call_expr: *Expr.Call, args: []const Value.Derived, env: Expr.EvalEnv) Expr.eval.Error!Value {
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
                    tuple[i] = @field(args[i].val, @tagName(e));
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
    const Error = Expr.eval.Error;

    pub fn min(x: f32, y: f32, _: Expr.EvalEnv) Error!Value {
        return .{ .number = @min(x, y) };
    }

    pub fn max(x: f32, y: f32, _: Expr.EvalEnv) Error!Value {
        return .{ .number = @max(x, y) };
    }

    pub fn floor(x: f32, _: Expr.EvalEnv) Error!Value {
        return .{ .number = @floor(x) };
    }

    pub fn ceil(x: f32, _: Expr.EvalEnv) Error!Value {
        return .{ .number = @ceil(x) };
    }

    pub fn trunc(x: f32, _: Expr.EvalEnv) Error!Value {
        return .{ .number = @trunc(x) };
    }

    pub fn round(x: f32, _: Expr.EvalEnv) Error!Value {
        return .{ .number = @round(x) };
    }

    pub fn sqrt(v: Value.Derived, env: Expr.EvalEnv) Error!Value {
        try Value.validate(v, &.{.number}, env.diag);
        if (v.val.number < 0) return env.err(.{ .invalid_argument = .{
            .reason = "cannot compute square root of negative number",
            .location = v.src.loc(),
        } });
        return .{ .number = @sqrt(v.val.number) };
    }

    pub fn abs(x: f32, _: Expr.EvalEnv) Error!Value {
        return .{ .number = @abs(x) };
    }

    pub fn cos(x: f32, _: Expr.EvalEnv) Error!Value {
        return .{ .number = @cos(x) };
    }

    pub fn sin(x: f32, _: Expr.EvalEnv) Error!Value {
        return .{ .number = @sin(x) };
    }

    pub fn prop(key: []const u8, env: Expr.EvalEnv) Error!Value {
        return (try env.context.obj(env)).get(key) orelse .nil;
    }

    pub fn len(value: Value.Derived, env: Expr.EvalEnv) Error!Value {
        try Value.validate(value, &.{ .string, .object, .array }, env.diag);
        return .{ .number = switch (value.val) {
            .string => |s| @floatFromInt(s.len),
            .object => |o| @floatFromInt(o.len()),
            .array => |a| @floatFromInt(a.len()),
            else => unreachable,
        } };
    }

    pub fn idx(needle: Value.Derived, haystack: Value.Derived, env: Expr.EvalEnv) Error!Value {
        try Value.validate(haystack, &.{ .string, .array }, env.diag);
        switch (haystack.val) {
            .string => |s| {
                try Value.validate(needle, &.{.string}, env.diag);
                const index = std.mem.indexOf(u8, s, needle.val.string);
                return if (index) |i| .{ .number = @floatFromInt(i) } else .nil;
            },
            .array => |a| {
                for (0..a.len()) |i| {
                    const item = a.get(i) catch unreachable;
                    if (Value.eql(item, needle.val)) return .{ .number = @floatFromInt(i) };
                }
                return .nil;
            },
            else => unreachable,
        }
    }

    pub fn lastIdx(needle: Value.Derived, haystack: Value.Derived, env: Expr.EvalEnv) Error!Value {
        try Value.validate(haystack, &.{ .string, .array }, env.diag);
        switch (haystack.val) {
            .string => |s| {
                try Value.validate(needle, &.{.string}, env.diag);
                const index = std.mem.lastIndexOf(u8, s, needle.val.string);
                return if (index) |i| .{ .number = @floatFromInt(i) } else .nil;
            },
            .array => |a| {
                for (a.len()..0) |i| {
                    const item = a.get(i) catch unreachable;
                    if (Value.eql(item, needle.val)) return .{ .number = @floatFromInt(i) };
                }
                return .nil;
            },
            else => unreachable,
        }
    }

    pub fn push(item: Value.Derived, list: Value.List, _: Expr.EvalEnv) Error!Value {
        try list.push(item.val);
        return .nil;
    }

    pub fn pop(list: Value.List, _: Expr.EvalEnv) Error!Value {
        return list.pop() orelse .nil;
    }

    pub fn slice(val: []const u8, start: Value.Derived, length: Value.Derived, env: Expr.EvalEnv) Error!Value {
        try Value.validate(start, &.{.number}, env.diag);
        try Value.validate(length, &.{ .number, .nil }, env.diag);

        if (@rem(start.val.number, 1) != 0) return env.err(.{ .invalid_argument = .{
            .reason = "start index must be an integer",
            .location = start.src.loc(),
        } });

        const l: usize = if (length.val == .number) blk: {
            if (@rem(length.val.number, 1) != 0) return env.err(.{ .invalid_argument = .{
                .reason = "substring length must be an integer",
                .location = length.src.loc(),
            } });
            if (length.val.number < 0) return env.err(.{ .invalid_argument = .{
                .reason = "substring length cannot be negative",
                .location = length.src.loc(),
            } });
            break :blk @intFromFloat(length.val.number);
        } else std.math.maxInt(usize);

        if (start.val.number >= 0) {
            const off: usize = @intFromFloat(start.val.number);
            const index = if (off < val.len) off else val.len;
            const end = if (off + l < val.len) off + l else val.len;
            return .{ .string = val[index..end] };
        } else {
            const off: usize = @intFromFloat(@abs(start.val.number));
            const end = if (off - 1 < val.len) val.len - (off - 1) else 0;
            const index = if (l < end) end - l else 0;
            return .{ .string = val[index..end] };
        }
    }

    pub fn @"type"(any: Value.Derived, _: Expr.EvalEnv) Error!Value {
        return .{ .string = switch (any.val) {
            .nil => "nil",
            .string => "string",
            .number => "number",
            .object => "object",
            .array => "array",
            .func => "function",
            .asset => "asset",
        } };
    }

    pub fn str(any: Value.Derived, env: Expr.EvalEnv) Error!Value {
        if (any.val == .string) return any.val;
        return .{ .string = try std.fmt.allocPrint(
            env.allocator,
            "{f}",
            .{std.fmt.alt(any.val, .stringify)},
        ) };
    }

    pub fn num(any: Value.Derived, env: Expr.EvalEnv) Error!Value {
        try Value.validate(any, &.{ .string, .number }, env.diag);
        switch (any.val) {
            .number => return any.val,
            .string => |s| if (std.fmt.parseFloat(f32, s)) |n| {
                return .{ .number = n };
            } else |_| return env.err(.{ .invalid_argument = .{
                .reason = "could not convert string to number",
                .location = any.src.loc(),
            } }),
            else => unreachable,
        }
    }

    pub fn ctx(env: Expr.EvalEnv) Error!Value {
        return .{ .asset = env.context };
    }
};
