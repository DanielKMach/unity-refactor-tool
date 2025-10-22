const core = @import("core");
const std = @import("std");

const Where = @This();

expr: *core.Expr,

pub fn parse(tokens: *core.Token.Iterator, env: core.Stmt.ParseEnv) core.Stmt.ParseError!Where {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.WHERE)) return error.TokenMismatch;

    const condition = try core.Expr.parse(tokens, .{
        .allocator = env.allocator,
        .diag = env.diag,
    });

    return .{ .expr = condition };
}

pub fn cleanup(self: Where, allocator: std.mem.Allocator) void {
    self.expr.cleanup(allocator);
}
