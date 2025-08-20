const core = @import("core");

const This = @This();

left: *core.Expr,
op: core.Token,
right: *core.Expr,

pub fn init(left: *core.Expr, op: core.Token, right: *core.Expr) This {
    return .{ .left = left, .op = op, .right = right };
}

pub fn evaluate(self: This, env: core.Expr.RunEnv) anyerror!core.results.RuntimeResult(core.Expr.Value) {
    return switch (self.op.value) {
        .plus => core.Expr.ops.concat(self.left, self.right, env), // TODO: make also add numbers
        .minus => core.Expr.ops.subtract(self.left, self.right, env),
        .star => core.Expr.ops.multiply(self.left, self.right, env),
        .slash => core.Expr.ops.divide(self.left, self.right, env),
        .equal_equal => core.Expr.ops.equals(self.left, self.right, env),
        .bang_equal => core.Expr.ops.notEquals(self.left, self.right, env),
        .greater => core.Expr.ops.greaterThan(self.left, self.right, env),
        .less => core.Expr.ops.lessThan(self.left, self.right, env),
        .greater_equal => core.Expr.ops.greaterThanOrEqual(self.left, self.right, env),
        .less_equal => core.Expr.ops.lessThanOrEqual(self.left, self.right, env),
        .OR => core.Expr.ops.logicalOr(self.left, self.right, env),
        .AND => core.Expr.ops.logicalAnd(self.left, self.right, env),
        else => unreachable,
    };
}
