const std = @import("std");
const builtin = @import("builtin");
const usrl = @import("usrl");
const tracy = @import("tracy");
const CLI = @import("CLI.zig");

const log = std.log.scoped(.main);

pub const std_options: std.Options = .{
    .logFn = logFn,
};

pub fn main() !u8 {
    const start = std.time.milliTimestamp();

    var debug_allocator: std.heap.DebugAllocator(.{ .enable_memory_limit = true }) = undefined;
    defer _ = if (builtin.mode == .Debug) debug_allocator.deinit();
    var tracy_allocator: tracy.TracyAllocator = undefined;
    var allocator: std.mem.Allocator = std.heap.smp_allocator;

    if (builtin.mode == .Debug) {
        debug_allocator = .init;
        debug_allocator.backing_allocator = std.heap.smp_allocator;
        allocator = debug_allocator.allocator();
    }
    if (usrl.config.profiling) {
        tracy_allocator = .{ .child_allocator = allocator };
        allocator = tracy_allocator.allocator();
    }

    var in_buf: [4096]u8 = undefined;
    var out_buf: [4096]u8 = undefined;
    var err_buf: [4096]u8 = undefined;

    var in = std.fs.File.stdin().reader(&in_buf);
    var out = std.fs.File.stdout().writer(&out_buf);
    var err = std.fs.File.stderr().writer(&err_buf);

    var cwd = try std.fs.cwd().openDir(".", .{ .iterate = true, .access_sub_paths = true });
    defer cwd.close();

    const cli = CLI{
        .out = &out,
        .in = &in,
        .err = &err,
        .allocator = allocator,
        .cwd = cwd,
    };

    var args = try std.process.argsWithAllocator(allocator);
    _ = args.next(); // skip the first argument
    defer args.deinit();

    const success = try cli.process(&args);
    try out.interface.flush();

    log.info("Total memory allocated {d:.3}MB", .{@as(f32, @floatFromInt(debug_allocator.total_requested_bytes)) / 1000000.0});
    log.info("Total execution time {d}ms", .{std.time.milliTimestamp() - start});

    return if (success) 0 else 1;
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
    if (builtin.mode != .Debug) return;
    const color = switch (message_level) {
        .err => "\x1B[31m",
        .warn => "\x1B[33m",
        .debug => "\x1B[34m",
        .info => "\x1B[90m",
    };
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    var buffer: [64]u8 = undefined;
    const stderr = std.debug.lockStderrWriter(&buffer);
    defer std.debug.unlockStderrWriter();
    nosuspend stderr.print(color ++ level_txt ++ prefix2 ++ format ++ "\x1B[0m\n", args) catch return;
}

pub const ExecutionMode = enum {
    args,
    file,
    stdin,
    interactive,
};
