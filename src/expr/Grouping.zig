const core = @import("core");

const This = @This();

expr: *core.expr.Expr,

pub fn init(expr: *core.expr.Expr) This {
    return .{ .expr = expr };
}
