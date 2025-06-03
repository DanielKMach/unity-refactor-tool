const std = @import("std");
const core = @import("root");

const This = @This();

allocator: std.mem.Allocator,
statements: []core.stmt.Statement,
source: []const u8,

pub fn run(this: This, options: RunConfig) !core.results.RuntimeResult(void) {
    core.profiling.begin(run);
    defer core.profiling.stop();

    var arena = std.heap.ArenaAllocator.init(options.allocator);
    defer arena.deinit();

    for (this.statements) |stmt| {
        defer _ = arena.reset(.retain_capacity);
        const data = core.runtime.RuntimeEnv{
            .allocator = arena.allocator(),
            .out = options.out,
            .cwd = options.cwd,
        };
        const result = try stmt.run(data);
        switch (result) {
            .ok => {},
            .err => |err| return .ERR(err),
        }
    }
    return .OK(void{});
}

pub fn deinit(this: This) void {
    this.allocator.free(this.statements);
}

pub const RunConfig = struct {
    allocator: std.mem.Allocator,
    out: std.io.AnyWriter,
    cwd: std.fs.Dir,
};
