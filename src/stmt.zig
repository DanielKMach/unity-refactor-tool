const std = @import("std");
const core = @import("core");

const ParseResult = core.results.ParseResult;
const RuntimeResult = core.results.RuntimeResult;

pub const clse = @import("stmt/clse.zig");

pub const Show = @import("stmt/Show.zig");
pub const Rename = @import("stmt/Rename.zig");
pub const Evaluate = @import("stmt/Evaluate.zig");

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
            if (!@hasDecl(Stmt, "parse") or @TypeOf(Stmt.parse) != fn (*core.language.Tokenizer.TokenIterator) anyerror!ParseResult(Stmt)) {
                @compileError("Invalid parse function for field '" ++ f.name ++ "', expected signature: fn (*language.Tokenizer.TokenIterator) anyerror!results.ParseResult(" ++ @typeName(Stmt) ++ ")");
            }
            if (!@hasDecl(Stmt, "run") or @TypeOf(Stmt.run) != fn (Stmt, core.runtime.RuntimeEnv) anyerror!RuntimeResult(void)) {
                @compileError("Invalid run function for field '" ++ f.name ++ "', expected signature: fn (" ++ @typeName(Stmt) ++ ", runtime.RuntimeEnv) anyerror!results.RuntimeResult(void)");
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

    pub fn parse(tokens: *core.language.Tokenizer.TokenIterator) !ParseResult(Statement) {
        inline for (fields) |fld| {
            switch (try fld.type.parse(tokens)) {
                .ok => |ok| return .OK(try Statement.init(ok)),
                .err => |err| switch (err) {
                    .unknown => {},
                    else => |errr| return .ERR(errr),
                },
            }
        }
        return .ERR(.{ .unknown = void{} });
    }

    pub fn run(this: Statement, data: core.runtime.RuntimeEnv) !RuntimeResult(void) {
        const active = @tagName(this);
        inline for (fields) |fld| {
            if (std.mem.eql(u8, fld.name, active)) {
                const result = try fld.type.run(@field(this, fld.name), data);
                return switch (result) {
                    .ok => .OK(void{}),
                    .err => |err| .ERR(err),
                };
            }
        }
        unreachable;
    }
};
