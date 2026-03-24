const std = @import("std");
const core = @import("core");

fn ParseFn(comptime T: type) type {
    return fn (*core.Token.Iterator, Stmt.ParseEnv) Stmt.ParseError!T;
}

fn RunFn(comptime T: type) type {
    return fn (T, Stmt.RunEnv) Stmt.RunError!void;
}

fn CleanupFn(comptime T: type) type {
    return fn (T, std.mem.Allocator) void;
}

pub const Stmt = union(enum) {
    pub const clse = @import("stmt/clse.zig");

    pub const ParseEnv = struct {
        allocator: std.mem.Allocator,
        diag: *core.ParseDiagnostics,

        pub inline fn err(self: ParseEnv, e: core.ParseProblem) core.ParseDiagnostics.Error {
            return self.diag.push(e);
        }
    };

    pub const ParseError = core.ParseAllocError || error{TokenMismatch};

    pub const RunEnv = struct {
        allocator: std.mem.Allocator,
        transaction: *core.Transaction,
        diag: *core.RuntimeDiagnostics,
        out: *std.Io.Writer,
        proj: core.Project,

        pub inline fn err(self: RunEnv, e: core.RuntimeProblem) core.RuntimeDiagnostics.Error {
            return self.diag.push(e);
        }
    };

    pub const RunError = anyerror;

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

    pub fn parse(tokens: *core.Token.Iterator, env: ParseEnv) core.ParseAllocError!Stmt {
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

    pub fn run(this: Stmt, env: RunEnv) RunError!void {
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
