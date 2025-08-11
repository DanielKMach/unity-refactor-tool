const core = @import("core");

const This = @This();

left: *core.Expr,
op: core.Token,
right: *core.Expr,

pub fn init(left: *core.Expr, op: core.Token, right: *core.Expr) This {
    return .{ .left = left, .op = op, .right = right };
}
