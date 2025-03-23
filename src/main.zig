pub const language = @import("language.zig");
pub const errors = @import("errors.zig");
pub const cmds = @import("cmds.zig");

pub const Scanner = @import("Scanner.zig");
pub const RuntimeData = @import("RuntimeData.zig");
pub const Yaml = @import("Yaml.zig");

const std = @import("std");
const builtin = @import("builtin");

pub const std_options: std.Options = .{
    .logFn = log,
};

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = undefined;
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

    var data = RuntimeData{
        .allocator = allocator,
        .out = out.any(),
        .cwd = cwd,
        .verbose = true,
        .query = undefined,
    };

    while (args.next()) |arg| {
        defer _ = arena.reset(.retain_capacity);

        const tokenizeResult = try language.Tokenizer.tokenize(arg, allocator);
        if (tokenizeResult.isErr()) |err| {
            try errors.showCompilerError(out.any(), err, arg);
            return;
        }
        var tokens = tokenizeResult.ok;

        data.query = arg;

        switch (tokens.peek(1).?.hash()) {
            language.Tokenizer.Token.new(.keyword, "SHOW").hash() => {
                try runCommand(cmds.Show, &tokens, data);
            },
            language.Tokenizer.Token.new(.keyword, "RENAME").hash() => {
                try runCommand(cmds.Rename, &tokens, data);
            },
            else => {
                const Err = @FieldType(errors.CompilerError(void), "err");
                try errors.showCompilerError(out.any(), @as(Err, .{ .unknown_command = void{} }), arg);
                return;
            },
        }
    }
}

pub fn runCommand(Command: type, tokens: *language.Tokenizer.TokenIterator, data: RuntimeData) !void {
    const parseResult = try Command.parse(tokens);
    if (parseResult.isErr()) |err| {
        try errors.showCompilerError(data.out, err, data.query);
        return;
    }

    const runResult = try parseResult.ok.run(data);
    if (runResult.isErr()) |err| {
        try errors.showRuntimeError(data.out, err);
        return;
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
