const std = @import("std");

pub const parsing = @import("parsing.zig");
pub const results = @import("results.zig");
pub const stmt = @import("stmt.zig");
pub const runtime = @import("runtime.zig");
pub const profiling = @import("profiling.zig");

pub const Source = @import("Source.zig");
pub const Token = @import("Token.zig");

pub fn eval(source: Source, allocator: std.mem.Allocator, cwd: std.fs.Dir, out: std.io.AnyWriter) !results.USRLError(void) {
    const parser = parsing.Parser{
        .allocator = allocator,
    };
    const script = switch (try parser.parse(source)) {
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
