const std = @import("std");

const Parser = @import("Parser.zig");
const Tokenizer = @import("Tokenizer.zig");
const Show = @import("commands/Show.zig");
const RuntimeData = @import("RuntimeData.zig");

pub const std_options: std.Options = .{
    .logFn = log,
};

pub fn main() !void {
    const main_allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(main_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var tokenizer = Tokenizer{ .allocator = allocator };
    const out = std.io.getStdOut().writer();
    var cwd = try std.fs.cwd().openDir(".", .{ .iterate = true, .access_sub_paths = true });
    defer cwd.close();

    const data = RuntimeData{
        .allocator = allocator,
        .out = out.any(),
        .cwd = cwd,
    };

    var args = try std.process.argsWithAllocator(allocator);
    _ = args.next(); // skip the first argument

    while (args.next()) |arg| {
        const tokenizeResult = try tokenizer.tokenize(arg);
        if (tokenizeResult.isErr()) |err| {
            showCompilerError(err, arg);
            return;
        }
        var tokens = tokenizeResult.ok;
        const parseResult = try Show.parse(&tokens);
        if (parseResult.isErr()) |err| {
            showCompilerError(err, arg);
            return;
        }

        const runResult = try parseResult.ok.run(data);
        if (runResult.isErr()) |err| {
            showRuntimeError(err);
            return;
        }
    }
}

pub fn showCompilerError(errUnion: anytype, command: []const u8) void {
    std.debug.print("Compiler error: ", .{});
    switch (errUnion) {
        .never_closed_string => |err| {
            std.debug.print("Never closed string at index {d}\r\n", .{err.index});
            showLineHighlightRange(command, err.index, err.index);
        },
        .unexpected_token => |err| {
            if (err.expected_value) |expected_value| {
                std.debug.print("Unexpected token: Expected {s} '{s}', found {s} '{s}'\r\n", .{
                    @tagName(err.expected_type),
                    expected_value,
                    @tagName(err.found.type),
                    err.found.value,
                });
            } else {
                std.debug.print("Unexpected token type: Expected a {s}, found {s} '{s}'\r\n", .{
                    @tagName(err.expected_type),
                    @tagName(err.found.type),
                    err.found.value,
                });
            }
            showLineHighlight(command, err.found.value);
        },
        .unexpected_eof => |err| {
            if (err.expected_value) |expected_value| {
                std.debug.print("Unexpected end of file: Expected {s} '{s}'\r\n", .{
                    @tagName(err.expected_type),
                    expected_value,
                });
            } else {
                std.debug.print("Unexpected end of file: Expected a {s}\r\n", .{
                    @tagName(err.expected_type),
                });
            }
        },
        .unknown_command => {
            std.debug.print("Unknown command\r\n", .{});
        },
    }
}

pub fn showRuntimeError(errUnion: anytype) void {
    std.debug.print("Runtime error: ", .{});
    switch (errUnion) {
        .invalid_asset => |err| {
            std.debug.print("Invalid asset path '{s}'\r\n", .{err.path});
        },
        .invalid_path => |err| {
            std.debug.print("Invalid path '{s}'\r\n", .{err.path});
        },
    }
}

/// Shows a line with a highlight.
/// Asserts that `highlight` is a slice of `line`.
pub fn showLineHighlight(line: []const u8, highlight: []const u8) void {
    const zero = @intFromPtr(line.ptr);
    const start = @intFromPtr(highlight.ptr) - zero;
    const end = start + highlight.len - 1;

    std.debug.assert(end >= start);
    std.debug.assert(start < line.len);
    std.debug.assert(end < line.len);

    showLineHighlightRange(line, start, end);
}

pub fn showLineHighlightRange(line: []const u8, start: usize, end: usize) void {
    std.debug.assert(start <= end);
    std.debug.assert(start < line.len);
    std.debug.assert(end < line.len);

    std.debug.print("{s}\r\n", .{line});

    for (0..start) |_| {
        std.debug.print(" ", .{});
    }

    for (start..end + 1) |_| {
        std.debug.print("~", .{});
    }

    std.debug.print("\r\n", .{});
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
