const std = @import("std");
const core = @import("core");

pub const Class = union(enum) {
    pub const Type = @typeInfo(Class).@"union".tag_type orelse unreachable;

    pub const Literal = struct {
        token: core.Token,
    };

    pub const Unary = struct {
        op: core.Token,
        operand: *core.Expr,
    };

    pub const Binary = struct {
        left: *core.Expr,
        op: core.Token,
        right: *core.Expr,
    };

    pub const Ternary = struct {
        left: *core.Expr,
        middle: *core.Expr,
        right: *core.Expr,
    };

    pub const Grouping = struct {
        expr: *core.Expr,
    };

    unary: Unary,
    literal: Literal,
    binary: Binary,
    ternary: Ternary,
    grouping: Grouping,

    pub fn format(value: Class, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        switch (value) {
            .literal => |l| try writer.print("{s}", .{l.token.value}),
            .unary => |u| try writer.print("({s} {f})", .{ u.op.value, u.operand }),
            .binary => |b| try writer.print("({s} {f} {f})", .{ b.op.value, b.left, b.right }),
            .grouping => |g| try writer.print("(group {f})", .{g.expr}),
        }
    }
};
