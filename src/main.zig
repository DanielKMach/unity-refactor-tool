const std = @import("std");
const Parser = @import("Parser.zig");
const Tokenizer = @import("Tokenizer.zig");
const Show = @import("commands/Show.zig");

pub const std_options: std.Options = .{
    .logFn = log,
};

pub fn main() !void {
    const main_allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(main_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var args = try std.process.argsWithAllocator(allocator);
    _ = args.next(); // skip the first argument
    var tokenizer = Tokenizer{ .allocator = allocator };
    // var interpreter = Interpreter{ .allocator = allocator };

    while (args.next()) |arg| {
        const tokenizeResult = try tokenizer.tokenize(arg);
        if (tokenizeResult.isErr()) |err| {
            showCompilerError(err);
            return;
        }
        const parseResult = try Show.parse(tokenizeResult.ok);
        if (parseResult.isErr()) |err| {
            showCompilerError(err);
            return;
        }
        _ = try parseResult.ok.run(allocator);
    }
}

pub fn showCompilerError(errUnion: anytype) void {
    switch (errUnion) {
        .never_closed_string => |err| {
            std.debug.print("Error: Never closed string at index {d}\r\n", .{err.index});
        },
        .unexpected_token => |err| {
            std.debug.print("Error: Unexpected token: Expected a {s} '{s}', found a {s} '{s}'\r\n", .{
                @tagName(err.expected.type),
                err.expected.value,
                @tagName(err.found.type),
                err.found.value,
            });
        },
        .unexpected_token_type => |err| {
            std.debug.print("Error: Unexpected token type: Expected a {s}, found a {s} '{s}'\r\n", .{
                @tagName(err.expected),
                @tagName(err.found.type),
                err.found.value,
            });
        },
        .unknown_command => {
            std.debug.print("Error: Unknown command\r\n", .{});
        },
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

    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    const stderr = std.io.getStdErr().writer();
    var bw = std.io.bufferedWriter(stderr);
    const writer = bw.writer();

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    nosuspend {
        writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
        bw.flush() catch return;
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
