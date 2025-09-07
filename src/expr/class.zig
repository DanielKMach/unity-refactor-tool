const std = @import("std");
const core = @import("core");

pub const Class = union(enum) {
    pub const Type = @typeInfo(Class).@"union".tag_type orelse unreachable;

    pub const Grouping = struct {
        expr: *core.Expr,
    };

    pub const Literal = struct {
        token: core.Token,
    };

    pub const Binary = struct {
        left: *core.Expr,
        op: core.Token,
        right: *core.Expr,
    };

    pub const Unary = struct {
        op: core.Token,
        operand: *core.Expr,
    };

    grouping: Grouping,
    literal: Literal,
    binary: Binary,
    unary: Unary,

    pub fn format(value: Class, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        switch (value) {
            .grouping => |g| try writer.print("(group {f})", .{g.expr}),
            .literal => |l| try writer.print("{s}", .{l.token.value}),
            .binary => |b| try writer.print("({s} {f} {f})", .{ b.op.value, b.left, b.right }),
            .unary => |u| try writer.print("({s} {f})", .{ u.op.value, u.operand }),
        }
    }
};
