const core = @import("core");

const This = @This();

op: core.Token,
operand: *core.Expr,

pub fn init(op: core.Token, operand: *core.Expr) This {
    return .{ .op = op, .operand = operand };
}
