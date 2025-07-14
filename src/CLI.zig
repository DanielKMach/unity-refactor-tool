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
out: std.fs.File.Writer,
cwd: std.fs.Dir,

pub fn process(self: This, args: *std.process.ArgIterator) !bool {
    var mode: ExecutionMode = .args;

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
    const result = try urt.eval(query, self.allocator, self.cwd, self.out.any());
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

pub fn printParseError(out: std.fs.File.Writer, errUnion: urt.results.ParseError, command: []const u8) !void {
    const ansi = ANSI.init(out);
    try ansi.print("*r", "PARSING ERROR: ", .{});

    switch (errUnion) {
        .unknown => {
            try ansi.print("r", "Unknown statement\r\n", .{});
        },
        .never_closed_string => |err| {
            try ansi.print("r", "Never closed string at index {d}\r\n", .{err.index});
            try printLineHighlightRange(out, command, err.index, err.index);
        },
        .unexpected_token => |err| {
            {
                ansi.begin("r");
                defer ansi.end("r");
                try out.print("Unexpected token '{s}'", .{@tagName(err.found.value)});
                if (err.expected.len > 0) try out.print(", expected ", .{});
                for (err.expected, 0..) |expected_type, i| {
                    if (i > 0 and i != err.expected.len - 1) try out.print(", ", .{});
                    if (i != 0 and i == err.expected.len - 1) try out.print(" or ", .{});
                    try out.print("{s}", .{@tagName(expected_type)});
                }
                try out.print("\r\n", .{});
            }
            try printLineHighlight(out, command, err.found.lexeme);
        },
        .unexpected_character => |err| {
            try ansi.print("r", "Unexpected character '{c}'\r\n", .{err.character.*});
            try printLineHighlight(out, command, err.character[0..1]);
        },
        .invalid_csharp_identifier => |err| {
            try ansi.print("r", "Invalid C# identifier '{s}'\r\n", .{err.identifier});
            try printLineHighlight(out, command, err.token.lexeme);
        },
        .invalid_guid => |err| {
            try ansi.print("r", "Invalid GUID '{s}'\r\n", .{err.guid});
            try printLineHighlight(out, command, err.token.lexeme);
        },
        .invalid_number => |err| {
            try ansi.print("r", "Invalid number '{s}'\r\n", .{err.slice});
            try printLineHighlight(out, command, err.slice);
        },
        .duplicate_clause => |err| {
            try ansi.print("r", "Duplicate clause '{s}' appeared at:\r\n", .{err.clause});
            try printLineHighlight(out, command, err.first.lexeme);
            try ansi.print("r", "But also at:\r\n", .{});
            try printLineHighlight(out, command, err.second.lexeme);
        },
        .missing_clause => |err| {
            try ansi.print("r", "Missing clause '{s}'\r\n", .{err.clause});
            try printLineHighlight(out, command, err.placement.lexeme);
        },
        .multiple => |errs| {
            for (errs) |err| {
                try printParseError(out, err, command);
            }
        },
    }
}

pub fn printRuntimeError(out: std.fs.File.Writer, errUnion: urt.results.RuntimeError) !void {
    const ansi = ANSI.init(out);
    try ansi.print("*r", "RUNTIME ERROR: ", .{});

    switch (errUnion) {
        .invalid_asset => |err| {
            try ansi.print("r", "Invalid asset path '{s}'\r\n", .{err.path});
        },
        .invalid_path => |err| {
            try ansi.print("r", "Invalid path '{s}'\r\n", .{err.path});
        },
    }
}

/// Shows a line with a highlight.
/// Asserts that `highlight` is a slice of `source`.
pub fn printLineHighlight(out: std.fs.File.Writer, source: []const u8, highlight: []const u8) !void {
    const zero = @intFromPtr(source.ptr);
    const offset = @intFromPtr(highlight.ptr) - zero;
    const len = if (highlight.len == 0) 1 else highlight.len;

    try printLineHighlightRange(out, source, offset, len);
}

pub fn printLineHighlightRange(out: std.fs.File.Writer, source: []const u8, offset: usize, size: usize) !void {
    const line_start = std.mem.lastIndexOf(u8, source[0..offset], "\n") orelse 0;
    const line_end = (std.mem.indexOf(u8, source[offset..], "\n") orelse source[offset..].len) + offset;
    const highlight_offset = offset - line_start;

    const line_number = std.mem.count(u8, source[0..offset], "\n") + 1;
    const line = source[line_start..line_end];

    const ansi = ANSI.init(out);
    try ansi.print("*", "On line {d}: \r\n", .{line_number});
    try out.print("{s}\r\n", .{line});

    ansi.begin("g");
    defer ansi.end("g");

    try out.writeByteNTimes(' ', highlight_offset);
    try out.writeByte('^');
    if (size > 1) try out.writeByteNTimes('~', size - 1);

    try out.print("\r\n", .{});
}

/// Prints the standard help message to the given writer.
pub fn printHelp(out: std.fs.File.Writer) anyerror!void {
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
    enabled: bool = false,
    out: std.fs.File.Writer,

    pub fn init(out: std.fs.File.Writer) ANSI {
        var self = ANSI{ .out = out };
        _ = self.enable();
        return self;
    }

    pub fn begin(self: ANSI, tags: []const u8) void {
        if (!self.enabled) return;

        for (tags) |tag| {
            self.out.writeAll(switch (tag) {
                '*' => "\x1B[1m",
                '_' => "\x1B[4m",
                'r' => "\x1B[31m",
                'g' => "\x1B[32m",
                'b' => "\x1B[34m",
                'y' => "\x1B[33m",
                'c' => "\x1B[36m",
                'm' => "\x1B[35m",
                else => continue,
            }) catch continue;
        }
    }

    pub fn end(self: ANSI, tags: []const u8) void {
        if (!self.enabled) return;

        for (tags) |tag| {
            self.out.writeAll(switch (tag) {
                '*' => "\x1B[22m",
                '_' => "\x1B[24m",
                'r', 'g', 'b', 'y', 'c', 'm' => "\x1B[39m",
                else => continue,
            }) catch continue;
        }
    }

    pub fn print(self: ANSI, tags: []const u8, comptime format: []const u8, args: anytype) !void {
        if (!self.enabled) {
            try self.out.print(format, args);
            return;
        }

        self.begin(tags);
        defer self.end(tags);

        try self.out.print(format, args);
    }

    /// Enables ANSI escape codes for the needed platforms (windows).
    pub fn enable(self: *ANSI) bool {
        self.enabled = self.out.context.getOrEnableAnsiEscapeSupport();
        return self.enabled;
    }
};
