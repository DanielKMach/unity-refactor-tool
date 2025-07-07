const std = @import("std");

pub const language = @import("language.zig");
pub const results = @import("results.zig");
pub const stmt = @import("stmt.zig");
pub const runtime = @import("runtime.zig");
pub const profiling = @import("profiling.zig");

pub fn eval(query: []const u8, allocator: std.mem.Allocator, cwd: std.fs.Dir, out: std.io.AnyWriter) !results.USRLError(void) {
    const script = switch (try language.Parser.parse(query, allocator)) {
        .ok => |s| s,
        .err => |err| return .ERR(.{ .parsing = err }),
    };
    defer script.deinit();

    const config = runtime.Script.RunConfig{
        .allocator = allocator,
        .out = out,
        .cwd = cwd,
    };

    switch (try script.run(config)) {
        .ok => {},
        .err => |err| return .ERR(.{ .runtime = err }),
    }

    return .OK({});
}
