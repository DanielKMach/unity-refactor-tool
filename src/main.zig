pub const language = @import("language.zig");
pub const errors = @import("errors.zig");
pub const cmds = @import("cmds.zig");

pub const Scanner = @import("Scanner.zig");
pub const RuntimeData = @import("RuntimeData.zig");

const std = @import("std");

const Show = cmds.Show;

pub const std_options: std.Options = .{
    .logFn = log,
};

pub fn main() !void {
    const main_allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(main_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var tokenizer = language.Tokenizer{ .allocator = allocator };
    const out = std.io.getStdOut().writer();
    var cwd = try std.fs.cwd().openDir(".", .{ .iterate = true, .access_sub_paths = true });
    defer cwd.close();

    var data = RuntimeData{
        .allocator = allocator,
        .out = out.any(),
        .cwd = cwd,
        .verbose = true,
        .query = undefined,
    };

    var args = try std.process.argsWithAllocator(allocator);
    _ = args.next(); // skip the first argument

    while (args.next()) |arg| {
        const tokenizeResult = try tokenizer.tokenize(arg);
        if (tokenizeResult.isErr()) |err| {
            try errors.showCompilerError(out.any(), err, arg);
            return;
        }
        var tokens = tokenizeResult.ok;

        data.query = arg;
        const parseResult = try Show.parse(&tokens);
        if (parseResult.isErr()) |err| {
            try errors.showCompilerError(out.any(), err, arg);
            return;
        }

        const runResult = try parseResult.ok.run(data);
        if (runResult.isErr()) |err| {
            try errors.showRuntimeError(out.any(), err);
            return;
        }
    }
}

fn log(
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
