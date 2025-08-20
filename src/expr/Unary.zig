const core = @import("core");

const This = @This();

op: core.Token,
operand: *core.Expr,

pub fn init(op: core.Token, operand: *core.Expr) This {
    return .{ .op = op, .operand = operand };
}

pub fn evaluate(self: This, env: core.Expr.RunEnv) anyerror!core.results.RuntimeResult(core.Expr.Value) {
    return switch (self.op.value) {
        .minus => core.Expr.ops.negate(self.operand, env),
        .NOT => core.Expr.ops.logicalNot(self.operand, env),
        else => unreachable,
    };
}
