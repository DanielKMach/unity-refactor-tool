const std = @import("std");
const core = @import("core");

const Func = @This();
const Expr = core.Expr;
const Value = Expr.Value;
const yaml = core.yaml;

pub const BuiltinFn = fn (*Expr.Call, []const Value.Derived, Expr.eval.Env) Expr.eval.Error!Value;

ptr: *const BuiltinFn,

pub fn call(self: Func, call_expr: *Expr.Call, args: []const Value.Derived, env: Expr.eval.Env) Expr.eval.Error!Value {
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
    switch (info.params[params.len].type.?) {
        Expr.eval.Env => {},
        builtin.FuncEnv => {},
        else => {
            @compileError("The last parameter of 'func' must be of type " ++ @typeName(Expr.eval.Env) ++ " or " ++ @typeName(Expr.eval.Env) ++ ". Found " ++ @typeName(params[params.len].type) ++ ".");
        },
    }

    const Wrapper = struct {
        pub fn wrap(call_expr: *Expr.Call, args: []const Value.Derived, env: Expr.eval.Env) Expr.eval.Error!Value {
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
            tuple[params.len] = switch (@TypeOf(tuple[params.len])) {
                Expr.eval.Env => env,
                builtin.FuncEnv => .{
                    .call_expr = call_expr,
                    .base = env,
                },
                else => unreachable,
            };

            return @call(.auto, func, tuple);
        }
    };
    return .{ .ptr = Wrapper.wrap };
}

fn TupleFromParams(comptime params: []const std.builtin.Type.Fn.Param) type {
    var fields: [params.len]std.builtin.Type.StructField = undefined;
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
    const FuncEnv = struct {
        call_expr: *Expr.Call,
        base: Expr.eval.Env,
    };

    pub fn min(x: f32, y: f32, _: Expr.eval.Env) Error!Value {
        return .{ .number = @min(x, y) };
    }

    pub fn max(x: f32, y: f32, _: Expr.eval.Env) Error!Value {
        return .{ .number = @max(x, y) };
    }

    pub fn floor(x: f32, _: Expr.eval.Env) Error!Value {
        return .{ .number = @floor(x) };
    }

    pub fn ceil(x: f32, _: Expr.eval.Env) Error!Value {
        return .{ .number = @ceil(x) };
    }

    pub fn trunc(x: f32, _: Expr.eval.Env) Error!Value {
        return .{ .number = @trunc(x) };
    }

    pub fn round(x: f32, _: Expr.eval.Env) Error!Value {
        return .{ .number = @round(x) };
    }

    pub fn sqrt(v: Value.Derived, env: Expr.eval.Env) Error!Value {
        try Value.validate(v, &.{.number}, env.diag);
        if (v.val.number < 0) return env.err(.{ .invalid_argument = .{
            .reason = "cannot compute square root of negative number",
            .location = v.src.loc(),
        } });
        return .{ .number = @sqrt(v.val.number) };
    }

    pub fn abs(x: f32, _: Expr.eval.Env) Error!Value {
        return .{ .number = @abs(x) };
    }

    pub fn cos(x: f32, _: Expr.eval.Env) Error!Value {
        return .{ .number = @cos(x) };
    }

    pub fn sin(x: f32, _: Expr.eval.Env) Error!Value {
        return .{ .number = @sin(x) };
    }

    pub fn prop(key: []const u8, env: Expr.eval.Env) Error!Value {
        return (env.context.obj(env) catch unreachable).get(key) orelse .nil;
    }

    pub fn len(value: Value.Derived, env: Expr.eval.Env) Error!Value {
        try Value.validate(value, &.{ .string, .object, .array }, env.diag);
        return .{ .number = switch (value.val) {
            .string => |s| @floatFromInt(s.len),
            .object => |o| @floatFromInt(o.len()),
            .array => |a| @floatFromInt(a.len()),
            else => unreachable,
        } };
    }

    pub fn idx(needle: Value.Derived, haystack: Value.Derived, env: Expr.eval.Env) Error!Value {
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

    pub fn lastIdx(needle: Value.Derived, haystack: Value.Derived, env: Expr.eval.Env) Error!Value {
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

    pub fn push(item: Value.Derived, list: Value.List, fenv: FuncEnv) Error!Value {
        if (fenv.base.readonly) return fenv.base.err(.{ .update_during_readonly_eval = .{
            .location = @as(*Expr, @fieldParentPtr("call", fenv.call_expr)).loc(),
        } });
        list.push(item.val) catch |err| switch (err) {
            error.UnrepresentableValue => return fenv.base.err(.{ .invalid_argument = .{
                .reason = "cannot convert value into node",
                .location = item.src.loc(),
            } }),
            else => |er| return er,
        };
        return .nil;
    }

    pub fn pop(list: Value.List, fenv: FuncEnv) Error!Value {
        if (fenv.base.readonly) return fenv.base.err(.{ .update_during_readonly_eval = .{
            .location = @as(*Expr, @fieldParentPtr("call", fenv.call_expr)).loc(),
        } });
        return list.pop() orelse .nil;
    }

    pub fn slice(val: []const u8, start: Value.Derived, length: Value.Derived, env: Expr.eval.Env) Error!Value {
        try Value.validate(start, &.{.number}, env.diag);
        try Value.validate(length, &.{.number}, env.diag);

        if (@rem(start.val.number, 1) != 0) return env.err(.{ .invalid_argument = .{
            .reason = "start index must be an integer",
            .location = start.src.loc(),
        } });
        if (@rem(length.val.number, 1) != 0) return env.err(.{ .invalid_argument = .{
            .reason = "substring length must be an integer",
            .location = length.src.loc(),
        } });
        if (length.val.number == 0) return .{ .string = "" };

        const vlen: isize = @intCast(val.len);
        const tlen: isize = @intFromFloat(length.val.number);
        const off: isize = @intFromFloat(start.val.number);
        const ix: isize = @intCast(if (off < 0) vlen + off else off);
        const iy: isize = @intCast(if (tlen < 0) ix + tlen + 1 else ix + tlen - 1);
        const s: usize = @intCast(@min(@max(@min(ix, iy), 0), val.len));
        const e: usize = @intCast(@min(@max(@max(ix, iy) + 1, 0), val.len));
        return .{ .string = val[s..e] };
    }

    pub fn @"type"(any: Value.Derived, _: Expr.eval.Env) Error!Value {
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

    pub fn str(any: Value.Derived, env: Expr.eval.Env) Error!Value {
        if (any.val == .string) return any.val;
        return .{ .string = try std.fmt.allocPrint(
            env.allocator,
            "{f}",
            .{std.fmt.alt(any.val, .stringify)},
        ) };
    }

    pub fn num(any: Value.Derived, env: Expr.eval.Env) Error!Value {
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

    pub fn ctx(env: Expr.eval.Env) Error!Value {
        return .{ .asset = env.context };
    }

    pub fn addList(fenv: FuncEnv) Error!Value {
        const env = fenv.base;
        if (env.readonly) return env.err(.{ .update_during_readonly_eval = .{
            .location = @as(*Expr, @fieldParentPtr("call", fenv.call_expr)).loc(),
        } });
        const ctx_obj = env.context.obj(env) catch |err| switch (err) {
            error.OutOfMemory, error.USRLRuntimeError, error.LibyamlError => |e| return e,
            else => unreachable,
        };
        const new_list = yaml.ly.yaml_document_add_sequence(ctx_obj.doc, null, yaml.ly.YAML_BLOCK_SEQUENCE_STYLE);
        if (new_list == 0) return error.LibyamlError;
        const nodes = yaml.fromStack(yaml.Node, ctx_obj.doc.nodes);
        return .{ .array = .{
            .node = &nodes[@intCast(new_list - 1)],
            .doc = ctx_obj.doc,
        } };
    }

    pub fn addObj(fenv: FuncEnv) Error!Value {
        const env = fenv.base;
        if (env.readonly) return env.err(.{ .update_during_readonly_eval = .{
            .location = @as(*Expr, @fieldParentPtr("call", fenv.call_expr)).loc(),
        } });
        const ctx_obj = env.context.obj(env) catch |err| switch (err) {
            error.OutOfMemory, error.USRLRuntimeError, error.LibyamlError => |e| return e,
            else => unreachable,
        };
        const new_obj = yaml.ly.yaml_document_add_mapping(ctx_obj.doc, null, yaml.ly.YAML_BLOCK_MAPPING_STYLE);
        if (new_obj == 0) return error.LibyamlError;
        const nodes = yaml.fromStack(yaml.Node, ctx_obj.doc.nodes);
        return .{ .array = .{
            .node = &nodes[@intCast(new_obj - 1)],
            .doc = ctx_obj.doc,
        } };
    }
};
