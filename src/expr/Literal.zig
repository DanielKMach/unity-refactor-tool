const core = @import("core");

const This = @This();

token: core.Token,

pub fn init(token: core.Token) This {
    return .{ .token = token };
}

pub fn evaluate(self: This, env: core.Expr.RunEnv) anyerror!core.results.RuntimeResult(core.Expr.Value) {
    return .OK(switch (self.token.value) {
        .number => |num| .{ .number = num },
        .string => |str| .{ .string = str },
        .literal => |lit| env.vars.get(lit) orelse .nil,
        else => unreachable, // TODO: array and object
    });
}
