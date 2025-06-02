const std = @import("std");
const core = @import("root");

const This = @This();

statements: []core.stmt.Statement,
source: []const u8,

pub fn run(this: This, options: RunConfig) !core.results.RuntimeResult(void) {
    core.profiling.begin(run);
    defer core.profiling.stop();

    const data = core.runtime.RuntimeEnv{
        .allocator = options.allocator,
        .out = options.out,
        .cwd = options.cwd,
    };

    for (this.statements) |stmt| {
        const result = try stmt.run(data);
        switch (result) {
            .ok => {},
            .err => |err| return .ERR(err),
        }
    }
    return .OK(void{});
}

pub const RunConfig = struct {
    allocator: std.mem.Allocator,
    out: std.io.AnyWriter,
    cwd: std.fs.Dir,
};
