const std = @import("std");
const core = @import("core");
const tracy = @import("tracy");

const This = @This();
const log = std.log.scoped(.script);

statements: []core.Stmt,

pub fn run(self: This, env: core.Stmt.RunEnv) anyerror!void {
    const zone = tracy.Zone(@src());
    defer zone.End();

    for (self.statements) |stmt| {
        try stmt.run(env);
    }
}

pub fn deinit(self: This, allocator: std.mem.Allocator) void {
    for (self.statements) |stmt| {
        stmt.deinit(allocator);
    }
    allocator.free(self.statements);
}
