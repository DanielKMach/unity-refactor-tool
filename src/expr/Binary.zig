const core = @import("core");

const This = @This();

left: *core.expr.Expr,
op: core.Token,
right: *core.expr.Expr,

pub fn init(left: *core.expr.Expr, op: core.Token, right: *core.expr.Expr) This {
    return .{ .left = left, .op = op, .right = right };
}
