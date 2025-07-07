const builtin = @import("builtin");
const std = @import("std");
const urt = @import("urt");

const This = @This();
const log = std.log.scoped(.cli);

pub const ExecutionMode = enum {
    args,
    file,
    stdin,
    interactive,
};

allocator: std.mem.Allocator,
out: std.io.AnyWriter,
cwd: std.fs.Dir,

pub fn process(self: This, args: *std.process.ArgIterator) !bool {
    var mode: ExecutionMode = .args;

    ANSI.enable();

    if (args.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "--file") or std.mem.eql(u8, arg, "-f")) {
                mode = .file;
            } else if (std.mem.eql(u8, arg, "--")) {
                mode = .stdin;
            } else if (std.mem.eql(u8, arg, "--interactive") or std.mem.eql(u8, arg, "-i")) {
                mode = .interactive;
            } else if (std.mem.eql(u8, arg, "--manual") or std.mem.eql(u8, arg, "-m")) {
                try openManual();
                return true;
            } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
                try printHelp(self.out);
                return true;
            } else {
                try self.out.print("\x1b[31mUnknown option: {s}\x1b[0m\r\n", .{arg});
                try printHelp(self.out);
                return false;
            }
        } else {
            if (!try self.run(arg)) return false;
        }
    } else {
        try printHelp(self.out);
        return true;
    }

    switch (mode) {
        .file => {
            while (args.next()) |path| {
                const file = try self.cwd.openFile(path, .{ .mode = .read_only });
                defer file.close();

                const query = try file.readToEndAlloc(self.allocator, std.math.maxInt(u16));
                defer self.allocator.free(query);

                if (!try self.run(query)) return false;
            }
        },
        .stdin => {
            const query = try std.io.getStdIn().readToEndAlloc(self.allocator, std.math.maxInt(u16));
            defer self.allocator.free(query);

            if (!try self.run(query)) return false;
        },
        .args => {
            while (args.next()) |query| {
                if (!try self.run(query)) return false;
            }
        },
        .interactive => {
            const in = std.io.getStdIn().reader();

            while (true) {
                try self.out.writeAll(">> ");
                const line = try in.readUntilDelimiterOrEofAlloc(self.allocator, '\n', std.math.maxInt(u16)) orelse break;
                defer self.allocator.free(line);

                const query = std.mem.trim(u8, line, " \n\t\r");

                if (query.len == 0) {
                    continue; // skip empty lines
                }

                if (!try self.run(query)) return false;
            }
            try self.out.writeAll("\r\n");
        },
    }
    return true;
}

pub fn run(self: This, query: []const u8) !bool {
    const result = try urt.eval(query, self.allocator, self.cwd, self.out);
    switch (result) {
        .ok => return true,
        .err => |err| {
            switch (err) {
                .parsing => |parse_err| try printParseError(self.out, parse_err, query),
                .runtime => |runtime_err| try printRuntimeError(self.out, runtime_err),
            }
            return false;
        },
    }
}

pub fn printParseError(out: std.io.AnyWriter, errUnion: urt.results.ParseError, command: []const u8) !void {
    const ansi = ANSI.init(out);
    try ansi.red();
    defer ansi.reset() catch {};

    {
        try ansi.bold();
        defer ansi.unbold() catch {};
        try out.writeAll("PARSING ERROR: ");
    }

    switch (errUnion) {
        .unknown => {
            try out.print("Unknown statement\r\n", .{});
        },
        .never_closed_string => |err| {
            try out.print("Never closed string at index {d}\r\n", .{err.index});
            try printLineHighlightRange(out, command, err.index, err.index);
        },
        .unexpected_token => |err| {
            try out.print("Unexpected token '{s}'", .{@tagName(err.found.value)});
            if (err.expected.len > 0) try out.print(", expected ", .{});
            for (err.expected, 0..) |expected_type, i| {
                if (i > 0 and i != err.expected.len - 1) try out.print(", ", .{});
                if (i != 0 and i == err.expected.len - 1) try out.print(" or ", .{});
                try out.print("{s}", .{@tagName(expected_type)});
            }
            try out.print("\r\n", .{});
            try printLineHighlight(out, command, err.found.lexeme);
        },
        .unexpected_character => |err| {
            try out.print("Unexpected character '{c}'\r\n", .{err.character.*});
            try printLineHighlight(out, command, err.character[0..1]);
        },
        .invalid_csharp_identifier => |err| {
            try out.print("Invalid C# identifier '{s}'\r\n", .{err.identifier});
            try printLineHighlight(out, command, err.token.lexeme);
        },
        .invalid_guid => |err| {
            try out.print("Invalid GUID '{s}'\r\n", .{err.guid});
            try printLineHighlight(out, command, err.token.lexeme);
        },
        .invalid_number => |err| {
            try out.print("Invalid number '{s}'\r\n", .{err.slice});
            try printLineHighlight(out, command, err.slice);
        },
        .multiple => |errs| {
            for (errs) |err| {
                try printParseError(out, err, command);
            }
        },
    }
}

pub fn printRuntimeError(out: std.io.AnyWriter, errUnion: urt.results.RuntimeError) !void {
    const ansi = ANSI.init(out);
    try ansi.red();
    defer ansi.reset() catch {};

    {
        try ansi.bold();
        defer ansi.unbold() catch {};
        try out.writeAll("RUNTIME ERROR: ");
    }

    switch (errUnion) {
        .invalid_asset => |err| {
            try out.print("Invalid asset path '{s}'\r\n", .{err.path});
        },
        .invalid_path => |err| {
            try out.print("Invalid path '{s}'\r\n", .{err.path});
        },
    }
}

/// Shows a line with a highlight.
/// Asserts that `highlight` is a slice of `source`.
pub fn printLineHighlight(out: std.io.AnyWriter, source: []const u8, highlight: []const u8) !void {
    const zero = @intFromPtr(source.ptr);
    const offset = @intFromPtr(highlight.ptr) - zero;
    const len = if (highlight.len == 0) 1 else highlight.len;

    try printLineHighlightRange(out, source, offset, len);
}

pub fn printLineHighlightRange(out: std.io.AnyWriter, source: []const u8, offset: usize, size: usize) !void {
    const line_start = std.mem.lastIndexOf(u8, source[0..offset], "\n") orelse 0;
    const line_end = (std.mem.indexOf(u8, source[offset..], "\n") orelse source[offset..].len) + offset;
    const highlight_offset = offset - line_start;

    const line_number = std.mem.count(u8, source[0..offset], "\n") + 1;
    const line = source[line_start..line_end];

    const ansi = ANSI.init(out);
    defer ansi.reset() catch {};

    try ansi.reset();
    {
        try ansi.bold();
        defer ansi.unbold() catch {};
        try out.print("On line {d}:\r\n", .{line_number});
    }
    try out.print("{s}\r\n", .{line});

    try ansi.green();
    try out.writeByteNTimes(' ', highlight_offset);
    try out.writeByte('^');
    if (size > 1) try out.writeByteNTimes('~', size - 1);

    try out.print("\r\n", .{});
}

/// Prints the standard help message to the given writer.
pub fn printHelp(out: std.io.AnyWriter) anyerror!void {
    try out.writeAll(@embedFile("help.txt"));
}

/// Opens the language manual
pub fn openManual() anyerror!void {
    const cwd = std.fs.cwd();
    const manual_file = try cwd.createFile("manual.html", .{});
    try manual_file.writeAll(@embedFile("manual.html"));

    var buf: [256]u8 = undefined;
    const path = try cwd.realpath("manual.html", &buf);
    buf[path.len] = 0;

    openURL(@ptrCast(path));
}

/// Opens the given URL.
pub fn openURL(url: [:0]const u8) void {
    switch (builtin.os.tag) {
        .windows => {
            const windows = @cImport(@cInclude("windows.h"));
            _ = windows.ShellExecuteA(null, "open", url, null, null, windows.SW_SHOWNORMAL);
        },
        else => {
            const stdlib = @cImport(@cInclude("stdlib.h"));
            var buf: [256]u8 = undefined;
            @memcpy(buf[0..5], "open ");
            @memcpy(buf[5 .. url.len + 5], url);
            buf[url.len + 5] = 0;
            _ = stdlib.system(&buf);
            return;
        },
    }
}

pub const ANSI = struct {
    out: std.io.AnyWriter,

    pub fn init(out: std.io.AnyWriter) ANSI {
        return ANSI{ .out = out };
    }

    pub fn bold(self: ANSI) !void {
        try self.out.writeAll("\x1B[1m");
    }
    pub fn unbold(self: ANSI) !void {
        try self.out.writeAll("\x1B[22m");
    }

    pub fn red(self: ANSI) !void {
        try self.out.writeAll("\x1B[31m");
    }
    pub fn green(self: ANSI) !void {
        try self.out.writeAll("\x1B[32m");
    }

    pub fn reset(self: ANSI) !void {
        try self.out.writeAll("\x1B[0m");
    }

    /// Enables ANSI escape codes for the needed platforms (windows).
    pub fn enable() void {
        switch (builtin.os.tag) {
            .windows => {
                const api = @cImport(@cInclude("windows.h"));

                const console = api.GetStdHandle(api.STD_OUTPUT_HANDLE);
                var mode: api.DWORD = undefined;
                if (api.GetConsoleMode(console, &mode) == 0) return;
                mode |= api.ENABLE_VIRTUAL_TERMINAL_PROCESSING;
                _ = api.SetConsoleMode(console, mode);
            },
            else => {},
        }
    }
};
