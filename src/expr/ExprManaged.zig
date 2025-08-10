const core = @import("core");
const std = @import("std");

const Expr = core.expr.Expr;
const ExprManaged = @This();

pool: std.heap.MemoryPool(Expr),
expr: *Expr,

pub fn format(value: ExprManaged, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    return value.expr.format(fmt, options, writer);
}
