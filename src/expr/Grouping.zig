const core = @import("core");

const This = @This();

expr: *core.Expr,

pub fn init(expr: *core.Expr) This {
    return .{ .expr = expr };
}

pub fn evaluate(self: This, env: core.Expr.RunEnv) anyerror!core.results.RuntimeResult(core.Expr.Value) {
    return self.expr.evaluate(env);
}
