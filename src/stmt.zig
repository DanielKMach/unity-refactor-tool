const std = @import("std");
const core = @import("core");

const ParseResult = core.results.ParseResult;
const RuntimeResult = core.results.RuntimeResult;

pub const clse = @import("stmt/clse.zig");

pub const Show = @import("stmt/Show.zig");
pub const Rename = @import("stmt/Rename.zig");
pub const Evaluate = @import("stmt/Evaluate.zig");

fn ParseFn(comptime T: type) type {
    return fn (*core.parsing.Tokenizer.TokenIterator, core.parsing.ParsetimeEnv) anyerror!ParseResult(T);
}

fn RunFn(comptime T: type) type {
    return fn (T, core.runtime.RuntimeEnv) anyerror!RuntimeResult(void);
}

fn DeinitFn(comptime T: type) type {
    return fn (T, std.mem.Allocator) void;
}

pub const Statement = union(enum) {
    show: Show,
    rename: Rename,
    evaluate: Evaluate,

    const fields = @typeInfo(Statement).@"union".fields;

    comptime {
        for (fields) |f| {
            const Stmt = f.type;
            const info = @typeInfo(Stmt);
            if (info != .@"struct") {
                @compileError("Invalid type for field '" ++ f.name ++ "', expected a struct, got " ++ @tagName(info));
            }
            if (!core.util.hasFn(Stmt, "parse", ParseFn(Stmt))) {
                @compileError("Invalid parse function for field '" ++ f.name ++ "', expected signature: fn (*language.Tokenizer.TokenIterator) anyerror!results.ParseResult(" ++ @typeName(Stmt) ++ ")");
            }
            if (!core.util.hasFn(Stmt, "run", RunFn(Stmt))) {
                @compileError("Invalid run function for field '" ++ f.name ++ "', expected signature: fn (" ++ @typeName(Stmt) ++ ", runtime.RuntimeEnv) anyerror!results.RuntimeResult(void)");
            }
            if (!core.util.hasFn(Stmt, "deinit", DeinitFn(Stmt))) {
                @compileError("Invalid deinit function for field '" ++ f.name ++ "', expected signature: fn (" ++ @typeName(Stmt) ++ ", std.mem.Allocator) void");
            }
        }
    }

    pub fn init(stmt: anytype) !Statement {
        inline for (fields) |fld| {
            if (fld.type == @TypeOf(stmt)) {
                return @unionInit(Statement, fld.name, stmt);
            }
        }
        @compileError("Invalid type for Statement, received: " ++ @typeName(@TypeOf(stmt)));
    }

    pub fn parse(tokens: *core.parsing.Tokenizer.TokenIterator, env: core.parsing.ParsetimeEnv) !ParseResult(Statement) {
        inline for (fields) |fld| {
            switch (try fld.type.parse(tokens, env)) {
                .ok => |ok| return .OK(try Statement.init(ok)),
                .err => |err| switch (err) {
                    .unknown => {},
                    else => |errr| return .ERR(errr),
                },
            }
        }
        return .ERR(.{ .unknown = void{} });
    }

    pub fn run(this: Statement, env: core.runtime.RuntimeEnv) !RuntimeResult(void) {
        const active = @tagName(this);
        inline for (fields) |fld| {
            if (std.mem.eql(u8, fld.name, active)) {
                const result = try fld.type.run(@field(this, fld.name), env);
                return switch (result) {
                    .ok => .OK(void{}),
                    .err => |err| .ERR(err),
                };
            }
        }
        unreachable;
    }

    pub fn deinit(this: Statement, allocator: std.mem.Allocator) void {
        inline for (fields) |fld| {
            if (std.mem.eql(u8, fld.name, @tagName(this))) {
                fld.type.deinit(@field(this, fld.name), allocator);
                return;
            }
        }
        unreachable;
    }
};
