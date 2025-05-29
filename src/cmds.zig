const std = @import("std");
const core = @import("root");

const ParseResult = core.results.ParseResult;
const RuntimeResult = core.results.RuntimeResult;

pub const sub = @import("cmds/sub.zig");

pub const Show = @import("cmds/Show.zig");
pub const Rename = @import("cmds/Rename.zig");
pub const Evaluate = @import("cmds/Evaluate.zig");

pub const Statement = union(enum) {
    show: core.cmds.Show,
    rename: core.cmds.Rename,
    evaluate: core.cmds.Evaluate,

    const fields = @typeInfo(Statement).@"union".fields;

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
                    .unknown_command => {},
                    else => |errr| return .ERR(errr),
                },
            }
        }
        return .ERR(.{ .unknown_command = void{} });
    }

    pub fn run(this: Statement, data: core.runtime.RuntimeData) !RuntimeResult(void) {
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
