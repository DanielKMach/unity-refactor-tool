const core = @import("core");

const This = @This();

expr: *core.Expr,

pub fn init(expr: *core.Expr) This {
    return .{ .expr = expr };
}
