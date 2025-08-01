const core = @import("core");

const This = @This();

op: core.Token,
operand: *core.expr.Expr,

pub fn init(op: core.Token, operand: *core.expr.Expr) This {
    return .{ .op = op, .operand = operand };
}
