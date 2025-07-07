const std = @import("std");
const builtin = @import("builtin");
const urt = @import("urt");
const CLI = @import("CLI.zig");

const log = std.log.scoped(.main);

pub const std_options: std.Options = .{
    .logFn = logFn,
};

pub fn main() !void {
    defer urt.profiling.finalize();

    urt.profiling.begin(main);
    defer urt.profiling.stop();

    const start = std.time.milliTimestamp();

    var debug_allocator: std.heap.DebugAllocator(.{ .enable_memory_limit = true }) = undefined;
    defer _ = if (builtin.mode == .Debug) debug_allocator.deinit();

    const allocator = switch (builtin.mode) {
        .Debug => bdy: {
            debug_allocator = .init;
            debug_allocator.backing_allocator = std.heap.page_allocator;
            break :bdy debug_allocator.allocator();
        },
        else => std.heap.page_allocator,
    };

    const out = std.io.getStdOut().writer();
    var cwd = try std.fs.cwd().openDir(".", .{ .iterate = true, .access_sub_paths = true });
    defer cwd.close();

    const cli = CLI{
        .out = out.any(),
        .allocator = allocator,
        .cwd = cwd,
    };

    var args = try std.process.argsWithAllocator(allocator);
    _ = args.next(); // skip the first argument
    defer args.deinit();

    const exit_code: u8 = if (try cli.process(&args)) 0 else 1;

    log.info("Total memory allocated {d:.3}MB", .{@as(f32, @floatFromInt(debug_allocator.total_requested_bytes)) / 1000000.0});
    log.info("Total execution time {d}ms", .{std.time.milliTimestamp() - start});

    std.process.exit(exit_code);
}

/// Prints the standard help message to the given writer.
pub fn printHelp(out: std.io.AnyWriter) anyerror!void {
    try out.writeAll(@embedFile("help.txt"));
}

/// Prints the language manual to the given writer.
pub fn printManual(out: std.io.AnyWriter) anyerror!void {
    try out.writeAll(@embedFile("manual.txt"));
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
        .info => "\x1B[90m",
    };
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    const stderr = std.io.getStdErr().writer();
    var bw = std.io.bufferedWriter(stderr);
    const writer = bw.writer();

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    nosuspend {
        writer.print(color ++ level_txt ++ prefix2 ++ format ++ "\x1B[0m" ++ "\n", args) catch return;
        bw.flush() catch return;
    }
}

pub const ExecutionMode = enum {
    args,
    file,
    stdin,
    interactive,
};
