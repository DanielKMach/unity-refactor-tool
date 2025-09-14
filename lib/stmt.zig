const std = @import("std");
const core = @import("core");

fn ParseFn(comptime T: type) type {
    return fn (*core.Token.Iterator, Stmt.ParsingEnv) Stmt.ParseError!T;
}

fn RunFn(comptime T: type) type {
    return fn (T, Stmt.RuntimeEnv) Stmt.RuntimeError!void;
}

fn CleanupFn(comptime T: type) type {
    return fn (T, std.mem.Allocator) void;
}

pub const Stmt = union(enum) {
    pub const clse = @import("stmt/clse.zig");

    pub const ParsingEnv = struct {
        allocator: std.mem.Allocator,
        diag: *core.ParseDiagnostics,

        pub fn err(self: ParsingEnv, e: core.ParseProblem) core.ParseDiagnostics.Error {
            return self.diag.push(e);
        }
    };

    pub const ParseError = error{ USRLParseError, TokenMismatch } || std.mem.Allocator.Error;

    pub const RuntimeEnv = struct {
        allocator: std.mem.Allocator,
        transaction: *core.Transaction,
        diag: *core.RuntimeDiagnostics,
        out: *std.Io.Writer,
        cwd: std.fs.Dir,

        pub fn err(self: RuntimeEnv, e: core.RuntimeProblem) core.RuntimeDiagnostics.Error {
            return self.diag.push(e);
        }
    };

    pub const RuntimeError = anyerror;

    pub const Show = @import("stmt/Show.zig");
    pub const Rename = @import("stmt/Rename.zig");
    pub const Evaluate = @import("stmt/Evaluate.zig");

    show: Show,
    rename: Rename,
    evaluate: Evaluate,

    const fields = @typeInfo(Stmt).@"union".fields;

    comptime {
        for (fields) |f| {
            const StmtType = f.type;
            const info = @typeInfo(StmtType);
            if (info != .@"struct") {
                @compileError("Invalid type for field '" ++ f.name ++ "', expected a struct, got " ++ @tagName(info));
            }
            if (!core.util.hasFn(StmtType, "parse", ParseFn(StmtType))) {
                @compileError("Invalid parse function for field '" ++ f.name ++ "', expected signature: " ++ @typeName(ParseFn(StmtType)));
            }
            if (!core.util.hasFn(StmtType, "run", RunFn(StmtType))) {
                @compileError("Invalid run function for field '" ++ f.name ++ "', expected signature: " ++ @typeName(RunFn(StmtType)));
            }
            if (!core.util.hasFn(StmtType, "cleanup", CleanupFn(StmtType))) {
                @compileError("Invalid cleanup function for field '" ++ f.name ++ "', expected signature: " ++ @typeName(CleanupFn(StmtType)));
            }
        }
    }

    pub fn init(stmt: anytype) !Stmt {
        inline for (fields) |fld| {
            if (fld.type == @TypeOf(stmt)) {
                return @unionInit(Stmt, fld.name, stmt);
            }
        }
        @compileError("Invalid type for Statement, received: " ++ @typeName(@TypeOf(stmt)));
    }

    pub fn parse(tokens: *core.Token.Iterator, env: ParsingEnv) core.ParseAllocError!Stmt {
        inline for (fields) |fld| {
            if (fld.type.parse(tokens, env)) |stmt| {
                return init(stmt);
            } else |err| switch (err) {
                error.TokenMismatch => {},
                else => |e| return e,
            }
        }
        return env.err(.{ .unexpected_token = .{
            .found = tokens.next(),
            .expected = &.{ .SHOW, .RENAME, .EVAL },
        } });
    }

    pub fn run(this: Stmt, env: RuntimeEnv) RuntimeError!void {
        switch (this) {
            inline else => |active| try active.run(env),
        }
    }

    pub fn deinit(this: Stmt, allocator: std.mem.Allocator) void {
        switch (this) {
            inline else => |active| active.cleanup(allocator),
        }
    }
};
