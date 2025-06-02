pub const language = @import("language.zig");
pub const results = @import("results.zig");
pub const stmt = @import("stmt.zig");
pub const runtime = @import("runtime.zig");
pub const profiling = @import("profiling.zig");

const std = @import("std");
const builtin = @import("builtin");

const log = std.log.scoped(.main);

pub const std_options: std.Options = .{
    .logFn = logFn,
};

pub fn main() !void {
    defer profiling.finalize();

    profiling.begin(main);
    defer profiling.stop();

    const start = std.time.milliTimestamp();

    var debug_allocator: std.heap.DebugAllocator(.{ .enable_memory_limit = true }) = undefined;
    defer _ = if (builtin.mode == .Debug) debug_allocator.deinit();
    if (builtin.mode == .Debug) {
        debug_allocator = .init;
        debug_allocator.backing_allocator = std.heap.page_allocator;
    }

    const main_allocator = if (builtin.mode == .Debug) debug_allocator.allocator() else std.heap.page_allocator;

    if (builtin.mode == .Debug) {}

    const out = std.io.getStdOut().writer();
    var cwd = try std.fs.cwd().openDir(".", .{ .iterate = true, .access_sub_paths = true });
    defer cwd.close();

    var args = try std.process.argsWithAllocator(main_allocator);
    _ = args.next(); // skip the first argument
    defer args.deinit();

    var arena = std.heap.ArenaAllocator.init(main_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    while (args.next()) |arg| {
        defer _ = arena.reset(.retain_capacity);

        const script = switch (try language.Parser.parse(arg, allocator)) {
            .ok => |s| s,
            .err => |err| {
                try results.printParseError(out.any(), err, arg);
                continue;
            },
        };

        const config = runtime.Script.RunConfig{
            .allocator = allocator,
            .out = out.any(),
            .cwd = cwd,
        };

        switch (try script.run(config)) {
            .ok => {},
            .err => |err| {
                try results.printRuntimeError(out.any(), err);
                continue;
            },
        }
    }

    log.debug("Total memory allocated {d:.3}MB", .{@as(f32, @floatFromInt(debug_allocator.total_requested_bytes)) / 1000000.0});
    log.debug("Total execution time {d}ms", .{std.time.milliTimestamp() - start});
}

fn logFn(
    comptime message_level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    if (scope == .tokenizer or scope == .parse) {
        return;
    }

    const color = switch (message_level) {
        .err => "\x1B[31m",
        .warn => "\x1B[33m",
        .debug => "\x1B[34m",
        else => "",
    };
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    const stderr = std.io.getStdErr().writer();
    var bw = std.io.bufferedWriter(stderr);
    const writer = bw.writer();

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    nosuspend {
        writer.print(color ++ level_txt ++ prefix2 ++ format ++ "\x1B[39m" ++ "\n", args) catch return;
        bw.flush() catch return;
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
