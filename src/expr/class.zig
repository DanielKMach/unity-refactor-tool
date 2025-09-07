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
            .literal => |l| try writer.print("{f}", .{std.fmt.alt(l.token.value, .raw)}),
            .unary => |u| try writer.print("({f} {f})", .{ std.fmt.alt(u.op.value, .raw), u.operand }),
            .binary => |b| try writer.print("({f} {f} {f})", .{ std.fmt.alt(b.op.value, .raw), b.left, b.right }),
            .ternary => |t| try writer.print("(?: {f} {f} {f})", .{ t.left, t.middle, t.right }),
            .grouping => |g| try writer.print("(group {f})", .{g.expr}),
        }
    }
};
