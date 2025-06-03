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

    var args = try std.process.argsWithAllocator(allocator);
    _ = args.next(); // skip the first argument
    defer args.deinit();

    var mode: ExecutionMode = .args;

    if (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--file") or std.mem.eql(u8, arg, "-f")) {
            mode = .file;
        } else if (std.mem.eql(u8, arg, "--")) {
            mode = .stdin;
        } else {
            try execute(arg, allocator, cwd, out.any());
        }
    } else {
        // TODO: Print manual and quit
    }

    switch (mode) {
        .file => {
            while (args.next()) |path| {
                const file = try cwd.openFile(path, .{ .mode = .read_only });
                defer file.close();

                const query = try file.readToEndAlloc(allocator, std.math.maxInt(u16));
                defer allocator.free(query);

                try execute(query, allocator, cwd, out.any());
            }
        },
        .stdin => {
            const query = try std.io.getStdIn().readToEndAlloc(allocator, std.math.maxInt(u16));
            defer allocator.free(query);

            try execute(query, allocator, cwd, out.any());
        },
        .args => {
            while (args.next()) |query| {
                try execute(query, allocator, cwd, out.any());
            }
        },
    }

    log.info("Total memory allocated {d:.3}MB", .{@as(f32, @floatFromInt(debug_allocator.total_requested_bytes)) / 1000000.0});
    log.info("Total execution time {d}ms", .{std.time.milliTimestamp() - start});
}

pub fn execute(query: []const u8, allocator: std.mem.Allocator, cwd: std.fs.Dir, out: std.io.AnyWriter) !void {
    const script = switch (try language.Parser.parse(query, allocator)) {
        .ok => |s| s,
        .err => |err| {
            try results.printParseError(out, err, query);
            return error.ParseError;
        },
    };
    defer script.deinit();

    const config = runtime.Script.RunConfig{
        .allocator = allocator,
        .out = out,
        .cwd = cwd,
    };

    switch (try script.run(config)) {
        .ok => {},
        .err => |err| {
            try results.printRuntimeError(out, err);
            return error.RuntimeError;
        },
    }
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
};
